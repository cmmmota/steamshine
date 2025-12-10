#!/usr/bin/env bash
set -euo pipefail

# 0. head-less input quirk
export WLR_LIBINPUT_NO_DEVICES=1

# -------------------------------------------------------------
# 1. Environment defaults (overridable via –e in Helm values)
# -------------------------------------------------------------
export TZ="${TZ:-UTC}"

export DISPLAY_WIDTH="${DISPLAY_WIDTH:-2560}"
export DISPLAY_HEIGHT="${DISPLAY_HEIGHT:-1440}"
export DISPLAY_REFRESH_RATE="${DISPLAY_REFRESH_RATE:-60}"

export SUNSHINE_CAPTURE="${SUNSHINE_CAPTURE:-kms}"
export SUNSHINE_ENCODER="${SUNSHINE_ENCODER:-nvenc}"

# -------------------------------------------------------------
# 2. XDG runtime dir (Wayland socket lives here)
# -------------------------------------------------------------
# Secure the XDG_RUNTIME_DIR first (dbus requires 700)
export XDG_RUNTIME_DIR=/dev/shm/user/$(id -u)
mkdir -p "${XDG_RUNTIME_DIR}"
chmod 700 "${XDG_RUNTIME_DIR}"

# -------------------------------------------------------------
# 2.5 NVIDIA / Vulkan Setup
# -------------------------------------------------------------
# Dynamically locate the NVIDIA ICD to prevent swrast fallback
# The NVIDIA Container Toolkit mounts this file, but the location varies
if [ -f "/etc/vulkan/icd.d/nvidia_icd.json" ]; then
    export VK_DRIVER_FILES="/etc/vulkan/icd.d/nvidia_icd.json"
    echo "Found NVIDIA ICD at /etc/vulkan/icd.d/nvidia_icd.json"
elif [ -f "/usr/share/vulkan/icd.d/nvidia_icd.json" ]; then
    export VK_DRIVER_FILES="/usr/share/vulkan/icd.d/nvidia_icd.json"
    echo "Found NVIDIA ICD at /usr/share/vulkan/icd.d/nvidia_icd.json"
else
    echo "WARNING: NVIDIA ICD not found in standard locations. Vulkan may fallback to swrast!"
fi

# Ensure we look in 32-bit directories for Steam dependencies
# (The Container Toolkit might mount them, but they need to be in the path)
export LD_LIBRARY_PATH="/usr/lib32:/usr/lib:${LD_LIBRARY_PATH:-}"

# -------------------------------------------------------------
# 3. Audio Services (Critical for Steam stability)
# -------------------------------------------------------------
# Start DBus FIRST - PipeWire needs it!
dbus-daemon --session \
  --address="unix:path=${XDG_RUNTIME_DIR}/bus" \
  --fork
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
sleep 1

# Start PipeWire and WirePlumber in background
pipewire &
sleep 1
wireplumber &
sleep 1
# Start PipeWire PulseAudio adapter
pipewire-pulse &

# -------------------------------------------------------------
# 5. Launch Gamescope (Wayland compositor) under seatd,
#    then hand off to Sunshine.
#
#    • --backend drm             – real KMS backend (needed for XDG-OUTPUT)
#    • --expose-wayland          – make WAYLAND_DISPLAY visible to children
#    • --prefer-output           – force specific output if available
# -------------------------------------------------------------
exec /usr/bin/seatd-launch -- \
  gamescope \
    --backend drm \
    --expose-wayland \
    --prefer-output "HDMI-A-1" \
    -W "${DISPLAY_WIDTH}" \
    -H "${DISPLAY_HEIGHT}" \
    -r "${DISPLAY_REFRESH_RATE}" \
    -f \
    -- \
  sunshine
