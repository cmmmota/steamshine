#!/bin/bash

export XDG_RUNTIME_DIR=/tmp/xdg-runtime
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR
export WAYLAND_DISPLAY=wayland-1

export WLR_RENDER_DRM_DEVICE=/dev/dri/card0
export WLR_BACKENDS=headless
export WLR_HEADLESS_OUTPUTS=1

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
    gamescope -f \
        --rt \
        -f \
        -v \
        --steam \
        --expose-wayland \
        --backend headless \
        -- steam -tenfoot &
    STEAM_PID=$!
}

start_wayfire() {
    wayfire &
    WAYFIRE_PID=$!

    sleep 10
}

#Start compositor
start_wayfire

# Start services
start_sunshine
start_steam

# Wait for either process to exit
wait $STEAM_PID 