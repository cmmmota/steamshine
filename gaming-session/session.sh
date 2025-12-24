#!/bin/bash
# Dedicated session script for Gamescope

echo "[session] D-Bus address: $DBUS_SESSION_BUS_ADDRESS"

# Start PipeWire for audio
echo "[session] Starting PipeWire..."
pipewire 2>&1 | grep -v "RTKit\|system bus" &
sleep 1
pipewire-pulse 2>&1 | grep -v "RTKit\|system bus" &
sleep 1
wireplumber 2>&1 | grep -v "system-dbus\|modem-manager\|voice-call\|libcamera" &
sleep 2

# Start Gamescope with Steam
# -W 1920 -H 1080: Virtual resolution
# -r 60: Refresh rate
# --backend headless: No physical display
# --expose-wayland: Allow other apps to connect (like Sunshine)
# --steam: Integrated Steam support
echo "[session] Starting Gamescope..."
exec gamescope -W 1920 -H 1080 -r 60 --backend headless --expose-wayland -- steam -bigpicture
