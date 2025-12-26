#!/bin/bash
set -e

echo "[rig] Starting Steamshine Monitor (Sway Edition)..."
echo "[rig] XDG_RUNTIME_DIR: ${XDG_RUNTIME_DIR}"
echo "[rig] User: $(whoami) (uid: $(id -u))"

# 1. Cleanup stale sockets/files
rm -f ${XDG_RUNTIME_DIR}/wayland-*
rm -f ${XDG_RUNTIME_DIR}/sway-ipc.*.sock
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

# 7. Start Sway
echo "[rig] Starting Sway compositor..."
# Ensure libinput is enabled
unset WLR_LIBINPUT_NO_DEVICES

# Export headless backend settings
export XDG_SEAT=seat0
export WLR_BACKENDS=drm,libinput
export WLR_LIBSEAT_BACKEND=seatd
export WLR_NO_HARDWARE_CURSORS=1
export WLR_DRM_NO_MASTER=1

# Start sway
sway -c ~/.config/sway/config &
SWAY_PID=$!

# 8. Wait for Wayland socket
echo "[rig] Waiting for Wayland display..."
for i in {1..30}; do
    # Sway typically creates wayland-0, but we check for any
    W_SOCKET=$(ls ${XDG_RUNTIME_DIR}/wayland-* 2>/dev/null | head -n 1)
    if [ -S "$W_SOCKET" ]; then
        export WAYLAND_DISPLAY=$(basename $W_SOCKET)
        echo "[rig] Display found: ${WAYLAND_DISPLAY}"
        break
    fi
    sleep 0.5
done

if [ -z "${WAYLAND_DISPLAY}" ]; then
    echo "[rig] ERROR: Wayland socket not found"
    cat /tmp/sway.log
    exit 1
fi

# 9. Wait for Sway IPC socket
echo "[rig] Waiting for Sway IPC..."
for i in {1..20}; do
    IPC_SOCKET=$(ls ${XDG_RUNTIME_DIR}/sway-ipc.*.sock 2>/dev/null | head -n 1)
    if [ -S "$IPC_SOCKET" ]; then
        export SWAYSOCK=$IPC_SOCKET
        echo "[rig] IPC socket found: ${SWAYSOCK}"
        break
    fi
    sleep 0.5
done

# 10. Wait for Xwayland
echo "[rig] Waiting for Xwayland..."
for i in {1..30}; do
    if [ -S /tmp/.X11-unix/X0 ]; then
        export DISPLAY=:0
        echo "[rig] X11 display found: ${DISPLAY}"
        break
    fi
    sleep 0.5
done

# 11. Set resolution
STREAM_WIDTH=${STREAM_WIDTH:-1920}
STREAM_HEIGHT=${STREAM_HEIGHT:-1080}
STREAM_REFRESH=${STREAM_REFRESH:-60}

# if [ -n "$SWAYSOCK" ]; then
#     echo "[rig] Setting resolution: ${STREAM_WIDTH}x${STREAM_HEIGHT}@${STREAM_REFRESH}Hz"
#     swaymsg "output HEADLESS-1 resolution ${STREAM_WIDTH}x${STREAM_HEIGHT}@${STREAM_REFRESH}Hz" || echo "[rig] Warning: swaymsg failed"
# else
#     echo "[rig] Warning: Could not find SWAYSOCK, resolution might be default"
# fi

# 12. Ensure Sunshine Configuration
SUNSHINE_CONF="/home/gamer/.config/sunshine/sunshine.conf"
echo "[rig] Checking Sunshine configuration..."
mkdir -p $(dirname ${SUNSHINE_CONF})
if [ ! -f "${SUNSHINE_CONF}" ]; then
    echo "sunshine_name = Steamshine-Rig" > "${SUNSHINE_CONF}"
    echo "input_method = uinput" >> "${SUNSHINE_CONF}"
    echo "log_level = debug" >> "${SUNSHINE_CONF}"
fi
# Ensure uinput is the method (sed -i is safe here)
sed -i 's/^input_method.*/input_method = uinput/' "${SUNSHINE_CONF}" || echo "input_method = uinput" >> "${SUNSHINE_CONF}"

echo "[rig] Starting Sunshine..."
# Ensure Sunshine sees the Xwayland display
export DISPLAY=${DISPLAY:-:0}
# Start sunshine (it will pick up the config we just ensured)
sunshine "${SUNSHINE_CONF}" &
SUNSHINE_PID=$!

# 12. Start Steam in Big Picture mode
echo "[rig] Starting Steam..."
# We use a loop or wait for Steam to actually start
steam -gamepadui &
STEAM_PID=$!

# 13. Watchdog
echo "[rig] Services started (Sway: $SWAY_PID, Sunshine: $SUNSHINE_PID, Steam: $STEAM_PID)"
while true; do
    if ! kill -0 $SWAY_PID 2>/dev/null; then
        echo "[rig] Sway died. Exiting..."
        exit 1
    fi
    if ! kill -0 $SUNSHINE_PID 2>/dev/null; then
        echo "[rig] Sunshine died. Exiting..."
        exit 1
    fi
    # Steam might exit and restart or handle itself differently, 
    # but for this rig we usually want it alive.
    if ! kill -0 $STEAM_PID 2>/dev/null; then
        echo "[rig] Steam died. Check logs."
        # Don't exit immediately, Steam might just be restarting its UI
        sleep 5
        if ! pgrep -u gamer steam >/dev/null; then
             echo "[rig] Steam is gone. Exiting..."
             exit 1
        fi
    fi
    sleep 5
done
