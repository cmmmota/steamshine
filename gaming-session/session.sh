#!/bin/bash
# Dedicated session script for Sway + Gamescope

echo "[session] Cleaning up XDG_RUNTIME_DIR: ${XDG_RUNTIME_DIR}"
# Clean up ALL stale sockets from previous runs to avoid wayland-1/2/3 drift
rm -f /xdg/wayland-* /xdg/wayland-*.lock
rm -f /xdg/gamescope-* /xdg/gamescope-*.lock
rm -f /xdg/sway-ipc.*.sock

# Let Sway decide which display to take (it will pick the first available)
unset WAYLAND_DISPLAY

if [ -n "$DBUS_SESSION_BUS_ADDRESS" ]; then
    echo "export DBUS_SESSION_BUS_ADDRESS=\"$DBUS_SESSION_BUS_ADDRESS\"" > /tmp/dbus-session.env
    chmod 644 /tmp/dbus-session.env
fi

# Start a minimal D-Bus "system" bus for Steam's WebHelper (CEF)
# It expects the socket at /run/dbus/system_bus_socket
echo "[session] Starting dummy System D-Bus with minimal config..."
dbus-daemon --config-file=/etc/dbus-1/minimal-system.conf --nofork --nopidfile &
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

# Start Sway in background to capture its display name
echo "[session] Starting Sway..."
sway -c /tmp/sway-config.actual > /tmp/sway.log 2>&1 &
SWAY_PID=$!

echo "[session] Waiting for Sway to initialize Wayland socket..."
for i in {1..20}; do
    # Find the newest wayland socket
    NEWEST_SOCKET=$(ls -t /xdg/wayland-* 2>/dev/null | grep -v "\.lock" | head -n 1)
    if [ -n "$NEWEST_SOCKET" ]; then
        export WAYLAND_DISPLAY=$(basename "$NEWEST_SOCKET")
        echo "[session] Sway is running on ${WAYLAND_DISPLAY}"
        break
    fi
    sleep 0.5
done

# Keep script alive as long as Sway is running
wait $SWAY_PID
