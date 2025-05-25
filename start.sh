#!/bin/bash
set -e

HOME_DIR="/home/steamshine"
XDG_RUNTIME_DIR="$HOME_DIR/.run"
PULSE_RUNTIME_DIR="$XDG_RUNTIME_DIR/pulse"

# Prepare runtime dirs
mkdir -p "$XDG_RUNTIME_DIR"
mkdir -p "$PULSE_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

export XDG_RUNTIME_DIR="$HOME_DIR/.run"
export PULSE_RUNTIME_PATH="$PULSE_RUNTIME_DIR"
export PULSE_SERVER="unix:$PULSE_RUNTIME_DIR/native"
export WAYLAND_DISPLAY=wayland-0

# Set DISPLAY and gamescope params with defaults
export DISPLAY=":1"
DISPLAY_WIDTH="${DISPLAY_WIDTH:-1920}"
DISPLAY_HEIGHT="${DISPLAY_HEIGHT:-1080}"
DISPLAY_REFRESH_RATE="${DISPLAY_REFRESH_RATE:-60}"

# Start pulseaudio if not running
if ! pgrep pulseaudio > /dev/null 2>&1; then
  pulseaudio --start --exit-idle-time=-1
fi

# Start sunshine in background
#sunshine &

# Launch gamescope + steam in foreground
exec /usr/games/gamescope --rt -w $DISPLAY_WIDTH -h $DISPLAY_HEIGHT -r $DISPLAY_REFRESH_RATE -- steam -silent
