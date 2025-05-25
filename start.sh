#!/bin/bash
set -e

# Function to handle shutdown
shutdown() {
    echo "Shutting down..."
    kill -TERM $SUNSHINE_PID 2>/dev/null || true
    kill -TERM $STEAM_PID 2>/dev/null || true
    kill -TERM $WESTON_PID 2>/dev/null || true
    exit 0
}

# Trap SIGTERM and SIGINT
trap shutdown SIGTERM SIGINT

# Start Xorg with dummy display config
weston --backend=headless-backend.so --width=${DISPLAY_WIDTH:-1920} --height=${DISPLAY_HEIGHT:-1080} --refresh-rate=${DISPLAY_REFRESH_RATE:-60} &
WESTON_PID=$!

# Give Xorg a moment to initialize
sleep 3

# Set DISPLAY for Sunshine and other apps
export DISPLAY=:0

# Start Steam in the background
steam &
STEAM_PID=$!

# Start Sunshine
sunshine &
SUNSHINE_PID=$!

# Wait for any process to exit
wait -n

# If we get here, one of the processes has exited
shutdown 