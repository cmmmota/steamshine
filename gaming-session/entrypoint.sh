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
else
    echo "[entrypoint] WARNING: No GPU render device found. Gamescope might fail."
fi

# Export DISPLAY for XWayland (Steam needs this for its UI)
export DISPLAY=:0

# Start everything within a D-Bus session using the dedicated session script
echo "[entrypoint] Launching session via dbus-run-session..."
exec dbus-run-session -- /session.sh

