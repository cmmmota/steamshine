#!/bin/bash

echo "[entrypoint] Starting gaming session..."
echo "[entrypoint] XDG_RUNTIME_DIR: ${XDG_RUNTIME_DIR}"
echo "[entrypoint] WAYLAND_DISPLAY: ${WAYLAND_DISPLAY}"

# Ensure XDG_RUNTIME_DIR exists (permissions set in Dockerfile)
if [ ! -d "${XDG_RUNTIME_DIR}" ]; then
    echo "[entrypoint] Creating XDG_RUNTIME_DIR..."
    mkdir -p "${XDG_RUNTIME_DIR}"
    chmod 0700 "${XDG_RUNTIME_DIR}"
fi

# Check for GPU access
if [ -d "/dev/dri" ]; then
    echo "[entrypoint] Fixing /dev/dri permissions..."
    sudo chmod 666 /dev/dri/* || true
fi

if [ -e "/dev/dri/renderD128" ]; then
    echo "[entrypoint] GPU devices found in /dev/dri"
    ls -la /dev/dri/
    # Vulkan renderer appearing unstable with mesa-git/RDNA4 combination (Format XR24 error)
    # Switching to GLES2 for compositor stability. Games can still use Vulkan.
    export WLR_RENDERER=gles2
    echo "[entrypoint] Using ${WLR_RENDERER} renderer"
else
    echo "[entrypoint] WARNING: No GPU render device found. Using software rendering."
    export WLR_RENDERER=pixman
fi

# Start D-Bus session bus
echo "[entrypoint] Starting D-Bus session..."
eval "$(dbus-launch --sh-syntax)" 2>/dev/null || true
export DBUS_SESSION_BUS_ADDRESS

# Start PipeWire for audio (suppress non-critical warnings)
echo "[entrypoint] Starting PipeWire..."
pipewire 2>&1 | grep -v "RTKit\|system bus" &
sleep 1
pipewire-pulse 2>&1 | grep -v "RTKit\|system bus" &
sleep 1
wireplumber 2>&1 | grep -v "system-dbus\|modem-manager\|voice-call\|libcamera" &
sleep 2

# Start Sway in headless mode
echo "[entrypoint] Starting Sway (headless)..."
exec sway 2>&1

