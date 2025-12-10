#!/usr/bin/env bash
set -euo pipefail

# 0. head-less input quirk
export WLR_LIBINPUT_NO_DEVICES=1
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export EGL_PLATFORM=wayland

# -------------------------------------------------------------
# 0.5 Runtime Library Fixup (NVIDIA GBM)
# -------------------------------------------------------------
# Locate the injected NVIDIA GBM library
NVIDIA_GBM_LIB=$(find /usr -name "libnvidia-egl-gbm.so.1*" 2>/dev/null | head -n 1)

if [ -n "$NVIDIA_GBM_LIB" ]; then
    echo "Found NVIDIA GBM library at: $NVIDIA_GBM_LIB"
    # Symlink it to where Mesa expects it (we have write access to /usr/lib/gbm from Dockerfile)
    ln -sf "$NVIDIA_GBM_LIB" /usr/lib/gbm/nvidia-drm_gbm.so
    ln -sf "$NVIDIA_GBM_LIB" /usr/lib/gbm/dri_gbm.so
    
    # Also ensure the directory containing the original lib is in LD_LIBRARY_PATH
    LIB_DIR=$(dirname "$NVIDIA_GBM_LIB")
    export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}:${LIB_DIR}"
else
    echo "WARNING: Could not find libnvidia-egl-gbm.so injected in the container!"
fi

# -------------------------------------------------------------
# 1. Environment defaults (overridable via –e in Helm values)
# -------------------------------------------------------------
export TZ="${TZ:-UTC}"

export DISPLAY_WIDTH="${DISPLAY_WIDTH:-2560}"
export DISPLAY_HEIGHT="${DISPLAY_HEIGHT:-1440}"
export DISPLAY_REFRESH_RATE="${DISPLAY_REFRESH_RATE:-60}"

export SUNSHINE_CAPTURE="wayland"
export SUNSHINE_ENCODER="${SUNSHINE_ENCODER:-nvenc}"

# Ensure Sunshine knows where to look
# export WAYLAND_DISPLAY="gamescope-0" # MOVED to wrapper invocation to prevent Gamescope nesting loop

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
  env SUNSHINE_CAPTURE="x11" DISPLAY=":0" /usr/local/bin/sunshine-wrapper.sh
