#!/usr/bin/env bash
set -eu

echo "[wrapper] Waiting for Wayland socket ${WAYLAND_DISPLAY}..."

# Wait loop (up to 30 seconds)
for i in $(seq 1 30); do
    if [ -e "${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY}" ]; then
        echo "[wrapper] Socket found! Launching Sunshine..."
        exec sunshine "$@"
    fi
    sleep 1
done

echo "[wrapper] Timeout waiting for Wayland socket."
exit 1
