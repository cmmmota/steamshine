#!/bin/bash
set -eu

# --- 1. XDG runtime for the user ---------------------------------
export XDG_RUNTIME_DIR=/tmp/xdg-runtime
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# --- 2. tiny session-bus (Steam helpers use it) ------------------
dbus-daemon --session --address=unix:path=$XDG_RUNTIME_DIR/bus --fork
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"

# --- 3. defaults overridable via env -----------------------------
export DISPLAY_WIDTH="${DISPLAY_WIDTH:-2560}"
export DISPLAY_HEIGHT="${DISPLAY_HEIGHT:-1440}"
export DISPLAY_REFRESH_RATE="${DISPLAY_REFRESH_RATE:-60}"
export WLR_RENDER_DRM_DEVICE=/dev/dri/card0

# --- 4. exec Sunshine under seatd-launch -------------------------
exec seatd-launch dbus-run-session sunshine