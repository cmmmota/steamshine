#!/bin/bash
set -e

echo "[entrypoint] Starting gaming session..."
echo "[entrypoint] XDG_RUNTIME_DIR: ${XDG_RUNTIME_DIR}"
echo "[entrypoint] WAYLAND_DISPLAY: ${WAYLAND_DISPLAY}"

# Ensure XDG_RUNTIME_DIR exists and has correct permissions
if [ ! -d "${XDG_RUNTIME_DIR}" ]; then
    echo "[entrypoint] Creating XDG_RUNTIME_DIR..."
    mkdir -p "${XDG_RUNTIME_DIR}"
fi
chmod 0700 "${XDG_RUNTIME_DIR}"

# Start PipeWire for audio
echo "[entrypoint] Starting PipeWire..."
pipewire &
sleep 1
pipewire-pulse &
sleep 1
wireplumber &
sleep 1

# Start Sway in headless mode
echo "[entrypoint] Starting Sway (headless)..."
exec sway

