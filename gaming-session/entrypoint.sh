#!/bin/bash

echo "[entrypoint] Starting gaming session..."
echo "[entrypoint] XDG_RUNTIME_DIR: ${XDG_RUNTIME_DIR}"
echo "[entrypoint] WAYLAND_DISPLAY: ${WAYLAND_DISPLAY}"

# Ensure XDG_RUNTIME_DIR is writable
if [ ! -w "${XDG_RUNTIME_DIR}" ]; then
    echo "[entrypoint] Fixing XDG_RUNTIME_DIR permissions..."
    sudo mkdir -p "${XDG_RUNTIME_DIR}"
    sudo chown gamer:gamer "${XDG_RUNTIME_DIR}"
    chmod 0700 "${XDG_RUNTIME_DIR}"
fi

# Check for GPU access
if [ -d "/dev/dri" ]; then
    echo "[entrypoint] Fixing /dev/dri permissions..."
    sudo chmod 666 /dev/dri/* || true
fi

# 2. Setup D-Bus system directory for Steam's WebHelper (needs /run/dbus/system_bus_socket)
echo "[entrypoint] Setting up System D-Bus directory..."
sudo mkdir -p /run/dbus
sudo chown gamer:gamer /run/dbus

if [ -e "/dev/dri/renderD128" ]; then
    echo "[entrypoint] GPU devices found in /dev/dri"
    ls -la /dev/dri/
    # Enable DRM device support even for headless backend (helps with DMABUF sharing)
    export WLR_DRM_DEVICES=/dev/dri/card0

    # Set Wayland renderer (remove gles2 force to allow Vulkan/Auto)
    # Vulkan renderer is unstable for Sway with mesa-git/RDNA4 (Format XR24 error)
    # Using GLES2 for the compositor. Games will still use Vulkan/RADV.
    # export WLR_RENDERER=gles2
    echo "[entrypoint] Using ${WLR_RENDERER} renderer for Sway"
else
    echo "[entrypoint] WARNING: No GPU render device found. Gamescope might fail."
fi

# Export DISPLAY for XWayland (Steam needs this for its UI)
export DISPLAY=:0

# Prepare Sway configuration with environment variables
echo "[entrypoint] Configuring display: ${STREAM_WIDTH}x${STREAM_HEIGHT}@${STREAM_REFRESH}Hz (HDR: ${STREAM_HDR})"
HDR_ARGS=""
if [ "$STREAM_HDR" = "true" ]; then
    HDR_ARGS="--hdr-enabled"
fi

# Apply substitutions to a temporary config file
sed -e "s/__WIDTH__/${STREAM_WIDTH}/g" \
    -e "s/__HEIGHT__/${STREAM_HEIGHT}/g" \
    -e "s/__REFRESH__/${STREAM_REFRESH}/g" \
    -e "s/__HDR_ARGS__/${HDR_ARGS}/g" \
    /home/gamer/.config/sway/config > /tmp/sway-config.actual

# Start everything within a D-Bus session using the dedicated session script
echo "[entrypoint] Launching session via dbus-run-session..."
exec dbus-run-session -- /session.sh

