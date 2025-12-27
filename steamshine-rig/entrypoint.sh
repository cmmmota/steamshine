#!/bin/bash
set -e

echo "[rig] Starting Steamshine Monitor (Hyprland Edition)..."
echo "[rig] XDG_RUNTIME_DIR: ${XDG_RUNTIME_DIR}"
echo "[rig] User: $(whoami) (uid: $(id -u))"

# 1. Cleanup stale sockets/files
rm -f ${XDG_RUNTIME_DIR}/wayland-*
rm -f ${XDG_RUNTIME_DIR}/hypr/*
rm -f /tmp/.X11-unix/X*

# Ensure input devices are accessible
if [ -d "/dev/input" ]; then
    echo "[entrypoint] Fixing /dev/input permissions..."
    # Grant access to event devices (keyboard/mouse/gamepad)
    sudo chmod -R 666 /dev/input/* || true
fi

if [ -e "/dev/uinput" ]; then
    echo "[entrypoint] Fixing /dev/uinput permissions..."
    sudo chmod 666 /dev/uinput || true
fi

# 2. Permissions for devices
# These might already be handled by init-perms, but let's be sure
if [ -d /dev/dri ]; then
    sudo chmod 666 /dev/dri/* || true
fi

# 4. Set file capabilities (Robustness fallback)
echo "[rig] Setting file capabilities..."
sudo setcap cap_sys_admin+ep $(readlink -f $(which sunshine)) || true
sudo setcap cap_sys_nice+ep $(readlink -f $(which pipewire)) || true
sudo setcap cap_sys_nice+ep $(readlink -f $(which gamemoded)) || true

# 5. Start D-Bus and seatd
sudo mkdir -p /run/dbus
sudo dbus-daemon --system --fork --nopidfile

echo "[rig] Starting seatd..."
sudo usermod -aG seat gamer || true
sudo seatd -g seat &
echo "[rig] Starting dumb-udev..."
sudo dumb-udev &
# Wait for seatd socket
for i in {1..10}; do
    if [ -S /run/seatd.sock ]; then
        echo "[rig] seatd socket found"
        break
    fi
    sleep 0.5
done

# Start session D-Bus
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
dbus-daemon --session --address="${DBUS_SESSION_BUS_ADDRESS}" --fork --nopidfile

# 6. Start PipeWire (audio)
echo "[rig] Starting Audio Stack..."
pipewire &
pipewire-pulse &
wireplumber &

# 7. Start Infrastructure
echo "[rig] Infrastructure services started (seatd, dumb-udev, dbus, audio)"

# 8. Ensure Sunshine Configuration
SUNSHINE_CONF="/home/gamer/.config/sunshine/sunshine.conf"
echo "[rig] Checking Sunshine configuration..."
mkdir -p $(dirname ${SUNSHINE_CONF})
if [ ! -f "${SUNSHINE_CONF}" ]; then
    echo "sunshine_name = Steamshine-Rig" > "${SUNSHINE_CONF}"
    echo "input_method = uinput" >> "${SUNSHINE_CONF}"
    echo "log_level = debug" >> "${SUNSHINE_CONF}"
fi
# Ensure uinput is the method
sed -i 's/^input_method.*/input_method = uinput/' "${SUNSHINE_CONF}" || echo "input_method = uinput" >> "${SUNSHINE_CONF}"

# 9. Start Sunshine
echo "[rig] Starting Sunshine (Application Gateway)..."
# Sunshine will launch the compositor upon connection (see apps.json)
sunshine "${SUNSHINE_CONF}" &
SUNSHINE_PID=$!

# 10. Watchdog
echo "[rig] Services started (Sunshine: $SUNSHINE_PID)"
while true; do
    if ! kill -0 $SUNSHINE_PID 2>/dev/null; then
        echo "[rig] Sunshine died. Exiting..."
        exit 1
    fi
    sleep 10
done
