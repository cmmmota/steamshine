#!/usr/bin/env bash
set -eu

echo "[wrapper] Waiting for Wayland socket ${WAYLAND_DISPLAY}..."

# Wait loop (up to 30 seconds)
for i in $(seq 1 30); do
    if [ -e "${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY}" ]; then
        echo "[wrapper] Socket found!"
        
        # Debug: List available Wayland globals
        echo "[wrapper] === Wayland Protocols Advertised by Gamescope ==="
        if command -v wayland-info &> /dev/null; then
            wayland-info 2>/dev/null | head -100 || true
        else
            echo "[wrapper] wayland-info not installed"
        fi
        echo "[wrapper] === End Wayland Protocols ==="
        
        # Check for PipeWire nodes
        echo "[wrapper] === PipeWire Nodes ==="
        if command -v pw-cli &> /dev/null; then
            pw-cli list-objects 2>/dev/null | head -50 || true
        else
            echo "[wrapper] pw-cli not available"
        fi
        echo "[wrapper] === End PipeWire ==="
        
        echo "[wrapper] Launching Sunshine with capture=wlr..."
        exec sunshine --capture wlr "$@"
    fi
    sleep 1
done

echo "[wrapper] Timeout waiting for Wayland socket."
exit 1
