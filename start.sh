#!/usr/bin/env bash
set -e

# --- 0. Cleanup & Traps ---
# Function to cleanup background processes on exit
cleanup() {
    echo "[start] Shutting down..."
    # Kill all child processes in the current process group
    pkill -P $$ || true
    wait
}
trap cleanup EXIT INT TERM

# --- 1. Environment Setup ---
# Try standard location first
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# Fallback to /tmp if needed
if [ ! -d "$XDG_RUNTIME_DIR" ]; then
    if ! mkdir -p "$XDG_RUNTIME_DIR" 2>/dev/null; then
        echo "[start] Cannot create $XDG_RUNTIME_DIR. Falling back to /tmp..."
        export XDG_RUNTIME_DIR="/tmp/runtime-$(id -u)"
    fi
fi

mkdir -p "${XDG_RUNTIME_DIR}"
chmod 700 "${XDG_RUNTIME_DIR}"

# Clean up stale sockets/locks
echo "[start] Cleaning up stale sockets..."
rm -rf "${XDG_RUNTIME_DIR}/pulse"
rm -f "${XDG_RUNTIME_DIR}/pipewire-0"
rm -f "${XDG_RUNTIME_DIR}/pipewire-0.lock"
rm -f "${XDG_RUNTIME_DIR}/wayland-0" 
rm -f "${XDG_RUNTIME_DIR}/gamescope-0"
rm -f "${XDG_RUNTIME_DIR}/bus"

export TZ="${TZ:-UTC}"
export DISPLAY_WIDTH="${DISPLAY_WIDTH:-1920}"
export DISPLAY_HEIGHT="${DISPLAY_HEIGHT:-1080}"
export DISPLAY_REFRESH="${DISPLAY_REFRESH:-60}"

# NOTE: Do NOT export WAYLAND_DISPLAY here. 
# Gamescope will set it for the nested session. 
# Exporting it here confuses Gamescope into thinking it's a nested client itself.

# --- 2. D-Bus Session ---
echo "[start] Starting D-Bus..."
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    if [ ! -f /etc/machine-id ]; then
        sudo dbus-uuidgen --ensure=/etc/machine-id
    fi
    # Start dbus-daemon
    dbus-daemon --session --address="unix:path=${XDG_RUNTIME_DIR}/bus" --fork --print-address
    export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
fi

# --- 3. Start Audio Services (PipeWire) ---
echo "[start] Starting Audio Stack..."
pipewire &
PID_PW=$!
sleep 1

wireplumber &
PID_WP=$!
sleep 1

pipewire-pulse &
PID_PWP=$!
sleep 1

# Check if they are still running
if ! kill -0 $PID_PW 2>/dev/null; then
    echo "[error] PipeWire died!"
    exit 1
fi
if ! kill -0 $PID_WP 2>/dev/null; then
    echo "[error] WirePlumber died!"
    exit 1
fi

# --- 4. Launch Gamescope ---
echo "[start] Launching Gamescope (AMD/Headless)..."

# Ensure /dev/uinput is writable (needed for Sunshine input)
if [ -e /dev/uinput ] && [ ! -w /dev/uinput ]; then
    echo "[start] Fixing /dev/uinput permissions..."
    sudo chmod 660 /dev/uinput
    sudo chown root:input /dev/uinput
fi

# Gamescope Arguments
# Note: We do NOT export XDG_RUNTIME_DIR for gamescope itself if we can help it, 
# but it NEEDS it to create sockets.
# The error "XDG_RUNTIME_DIR is invalid or not set in the environment" suggests gamescope
# is sanitizing the env or looking for it and failing.
#
# But strangely, when running manually:
# [gamescope] [Info]  wlserver: [wayland] error: XDG_RUNTIME_DIR is invalid or not set in the environment
# ...
# [gamescope] [Error] wlserver: Unable to open wayland socket: No such file or directory
#
# This implies gamescope cannot WRITE to the socket dir.
#
# Let's ensure XDG_RUNTIME_DIR is exported and valid.

# Force Mesa driver for VAAPI if not set
export LIBVA_DRIVER_NAME="${LIBVA_DRIVER_NAME:-radeonsi}"
# Force Vulkan driver (usually optional but good for debugging)
# export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json

exec gamescope \
    --backend headless \
    --expose-wayland \
    -W "${DISPLAY_WIDTH}" \
    -H "${DISPLAY_HEIGHT}" \
    -r "${DISPLAY_REFRESH}" \
    -- \
    /usr/local/bin/sunshine-wrapper.sh
