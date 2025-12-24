#!/bin/bash
# Dedicated session script for Sway + Gamescope

echo "[session] Cleaning up XDG_RUNTIME_DIR: ${XDG_RUNTIME_DIR}"
# Clean up stale sockets from previous runs
rm -f /xdg/wayland-* /xdg/wayland-*.lock
rm -f /xdg/gamescope-* /xdg/gamescope-*.lock
rm -f /xdg/sway-ipc.*.sock

# Ensure we have a fresh start for the display name
unset WAYLAND_DISPLAY

if [ -n "$DBUS_SESSION_BUS_ADDRESS" ]; then
    echo "export DBUS_SESSION_BUS_ADDRESS=\"$DBUS_SESSION_BUS_ADDRESS\"" > /tmp/dbus-session.env
    chmod 644 /tmp/dbus-session.env
fi

# Start a minimal D-Bus "system" bus for Steam's WebHelper (CEF)
# It expects the socket at /run/dbus/system_bus_socket
echo "[session] Starting dummy System D-Bus..."
dbus-daemon --config-file=/usr/share/dbus-1/system.conf --print-address --nofork --nopidfile --address=unix:path=/run/dbus/system_bus_socket &
sleep 1

# Force AMD RADV driver and prevent llvmpipe fallback
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json:/usr/share/vulkan/icd.d/radeon_icd.i686.json

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
