#!/bin/bash

export XDG_RUNTIME_DIR=/tmp/xdg-runtime
mkdir -p $XDG_RUNTIME_DIR
chmod 711 $XDG_RUNTIME_DIR

export WLR_RENDERER=vulkan
export WLR_BACKENDS=libinput,headless
export WLR_LIBINPUT_NO_DEVICES=1
export XDG_CURRENT_DESKTOP=sway
export XDG_SESSION_DESKTOP=sway
export XDG_SESSION_CLASS=user
export XDG_SESSION_TYPE=wayland

sudo ldconfig

# Function to start Sunshine with appropriate GPU settings
start_sunshine() {
    # Start Sunshine in the background
    sunshine &
    SUNSHINE_PID=$!
    #echo "Sunshine is disabled"
}

# Function to start Steam with Gamescope
start_steam() {
    # Start Steam with Gamescope
    # -f: Fullscreen
    # -W/-H: Resolution
    # -r: Refresh rate
    # -e: Enable Steam integration
    # -o: Enable HDR if available
    # --force-windows-fullscreen: Ensure proper fullscreen
    # --adaptive-sync: Enable VRR if available
    # --steam-bigpicture: Enable Steam Big Picture mode
    # dbus-run-session gamescope -f \
    #     --rt \
    #     -f \
    #     -v \
    #     --steam \
    #     --expose-wayland \
    #     --backend headless \
    #     -- steam -tenfoot &
    dbus-run-session steam -tenfoot &
    STEAM_PID=$!
}

start_sway() {
    seatd-launch &
    export SEATD_SOCK=$XDG_RUNTIME_DIR/seatd.sock

    sleep 1

    dbus-run-session sway --unsupported-gpu --seat seat0 &
    SWAY_PID=$!

    sleep 2
}

#Start compositor
start_sway

# Start services
start_sunshine
#start_steam

# Wait for either process to exit
wait $STEAM_PID 
#wait $SUNSHINE_PID