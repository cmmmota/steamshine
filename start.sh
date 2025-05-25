#!/bin/bash
set -e

# Start Xorg with dummy display config
Xorg :0 -config /etc/X11/xorg.conf -noreset +extension GLX +extension RANDR +extension RENDER +extension DAMAGE +extension MIT-SHM &

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

# Only wait for Sunshine to exit, as Steam may restart during updates
wait $SUNSHINE_PID 