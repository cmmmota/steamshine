#!/bin/bash
set -e

echo "[sunshine] Starting Sunshine streaming server..."
echo "[sunshine] XDG_RUNTIME_DIR: ${XDG_RUNTIME_DIR}"
echo "[sunshine] WAYLAND_DISPLAY: ${WAYLAND_DISPLAY}"

# Ensure XDG_RUNTIME_DIR permissions (important if shared volume)
sudo chown sunshine:sunshine "${XDG_RUNTIME_DIR}"
chmod 0700 "${XDG_RUNTIME_DIR}"

# Check if apps.json is mounted
if [ -f /config/apps.json ]; then
    echo "[sunshine] Found custom apps.json configuration"
    mkdir -p /home/sunshine/.config/sunshine
    cp /config/apps.json /home/sunshine/.config/sunshine/apps.json
fi

# Wait for Wayland socket if gaming session is already running
SOCKET_PATH="${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY}"
if [ -S "${SOCKET_PATH}" ]; then
    echo "[sunshine] Wayland socket found at ${SOCKET_PATH}"
else
    echo "[sunshine] WARNING: No Wayland socket found. Games will need to start the gaming session first."
fi

# Start Sunshine
echo "[sunshine] Launching Sunshine..."
exec sunshine /home/sunshine/.config/sunshine/sunshine.conf

