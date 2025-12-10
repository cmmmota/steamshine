#!/usr/bin/env bash
set -euo pipefail

#!/bin/bash

# --- 1. Force Nvidia Driver Configuration ---
# These are MANDATORY for Gamescope on Nvidia
export EGL_PLATFORM=surfaceless
export WLR_RENDERER=vulkan
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/10_nvidia.json

# [NEW] Force GBM Backend (Fixes 'zero modifiers' error)
export GBM_BACKEND=nvidia-drm
export WLR_BACKEND=headless

# --- 2. Auto-Launch D-Bus Session (Safe Mode) ---
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    echo "--- [Fix] No D-Bus found. Relaunching script inside dbus-run-session... ---"
    exec dbus-run-session -- "$0" "$@"
fi

# --- 3. Clean up previous locks ---
rm -rf /tmp/.X11-unix
rm -f /dev/shm/user/$(id -u)/pipewire-0-manager.lock

# ---------------------------------------------------------
# YOUR ORIGINAL SCRIPT STARTS BELOW THIS LINE
# ---------------------------------------------------------

# 0. Environment Setup
export XDG_RUNTIME_DIR=/dev/shm/user/$(id -u)
mkdir -p "${XDG_RUNTIME_DIR}"
chmod 700 "${XDG_RUNTIME_DIR}"

# --- CLEANUP STALE SOCKETS ---
echo "[start] Cleaning up stale sockets..."
rm -rf "${XDG_RUNTIME_DIR}/pulse"
rm -f "${XDG_RUNTIME_DIR}/pipewire-0"
rm -f "${XDG_RUNTIME_DIR}/pipewire-0.lock"
rm -f "${XDG_RUNTIME_DIR}/wayland-0" 
rm -f "${XDG_RUNTIME_DIR}/gamescope-0"

export TZ="${TZ:-UTC}"
export DISPLAY_WIDTH="${DISPLAY_WIDTH:-1920}"
export DISPLAY_HEIGHT="${DISPLAY_HEIGHT:-1080}"
export DISPLAY_REFRESH="${DISPLAY_REFRESH:-60}"

# 1. Start Audio Services (PipeWire)
echo "[start] Starting Audio Stack..."
if ! pgrep -x "dbus-daemon" > /dev/null; then
    dbus-daemon --session --address="unix:path=${XDG_RUNTIME_DIR}/bus" --fork
fi
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"

pipewire &
sleep 1
wireplumber &
sleep 1
pipewire-pulse &
sleep 1

# 2. NVIDIA / Vulkan / EGL Setup (Explicit Paths)
echo "[start] Configuring Graphics Drivers..."

# FORCE VULKAN ICD (Path verified from your diagnostics)
export VK_DRIVER_FILES="/etc/vulkan/icd.d/nvidia_icd.json"

# FORCE EGL VENDOR (Path verified from your diagnostics)
# This prevents Xwayland from falling back to software (which crashes)
export __EGL_VENDOR_LIBRARY_FILENAMES="/usr/share/glvnd/egl_vendor.d/10_nvidia.json"


# 3. Launch Gamescope
echo "[start] Launching Gamescope..."

# Using headless backend - NO seatd required
GAMESCOPE_BACKEND="headless" 

exec gamescope \
    --"${GAMESCOPE_BACKEND}" \
    --expose-wayland \
    -W "${DISPLAY_WIDTH}" \
    -H "${DISPLAY_HEIGHT}" \
    -r "${DISPLAY_REFRESH}" \
    -- \
  env /usr/local/bin/sunshine-wrapper.sh
