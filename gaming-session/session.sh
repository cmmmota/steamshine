#!/bin/bash
# Dedicated session script for Sway + Gamescope

echo "[session] D-Bus address: $DBUS_SESSION_BUS_ADDRESS"

# Start PipeWire for audio
echo "[session] Starting PipeWire..."
pipewire 2>&1 | grep -v "RTKit\|system bus" &
sleep 1
pipewire-pulse 2>&1 | grep -v "RTKit\|system bus" &
sleep 1
wireplumber 2>&1 | grep -v "system-dbus\|modem-manager\|voice-call\|libcamera" &
sleep 2

# Start Sway
# Sunshine will capture Sway's output.
# Steam will run inside Gamescope, which runs inside Sway.
echo "[session] Starting Sway..."
exec sway -c /tmp/sway-config.actual 2>&1
