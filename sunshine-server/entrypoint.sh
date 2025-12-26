#!/bin/bash
set -e

echo "[sunshine] Starting Sunshine streaming server..."
echo "[sunshine] XDG_RUNTIME_DIR: ${XDG_RUNTIME_DIR}"
echo "[sunshine] WAYLAND_DISPLAY: ${WAYLAND_DISPLAY}"

# Ensure XDG_RUNTIME_DIR is writable
if [ ! -w "${XDG_RUNTIME_DIR}" ]; then
    echo "[sunshine] WARNING: ${XDG_RUNTIME_DIR} is not writable. Attempting to fix..."
    sudo chown sunshine:sunshine "${XDG_RUNTIME_DIR}"
    chmod 0700 "${XDG_RUNTIME_DIR}"
fi

# Check if apps.json is mounted
if [ -f /config/apps.json ]; then
    echo "[sunshine] Found custom apps.json configuration"
    mkdir -p /home/sunshine/.config/sunshine
    cp /config/apps.json /home/sunshine/.config/sunshine/apps.json
fi

# 2. Wait for a Wayland socket to appear (up to 60s)
echo "[sunshine] Waiting for Wayland socket in ${XDG_RUNTIME_DIR}..."
for i in {1..120}; do
    # Find the first wayland-* socket
    FOUND_SOCKET=$(ls ${XDG_RUNTIME_DIR}/wayland-* 2>/dev/null | grep -v "\.lock" | head -n 1)
    if [ -n "${FOUND_SOCKET}" ]; then
        export WAYLAND_DISPLAY=$(basename "${FOUND_SOCKET}")
        echo "[sunshine] Found Wayland display: ${WAYLAND_DISPLAY}"
        break
    fi
    sleep 0.5
done

# Check if WAYLAND_DISPLAY is set
if [ -z "${WAYLAND_DISPLAY}" ]; then
    echo "[sunshine] ERROR: Timed out waiting for Wayland socket. Sunshine will likely fail."
fi

# Start Sunshine
echo "[sunshine] Launching Sunshine..."
exec sunshine /home/sunshine/.config/sunshine/sunshine.conf
