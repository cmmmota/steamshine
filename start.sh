#!/bin/bash

# Function to start Sunshine with appropriate GPU settings
start_sunshine() {
    # Start Sunshine in the background
    sunshine &
    SUNSHINE_PID=$!
    #echo "Sunshine is disabled"
}

# Function to start Steam with Gamescope
start_steam() {
    export XDG_RUNTIME_DIR=/tmp/xdg-runtime
    mkdir -p $XDG_RUNTIME_DIR
    chmod 700 $XDG_RUNTIME_DIR
    export WAYLAND_DISPLAY=wayland-0
    
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
        -W $DISPLAY_WIDTH \
        -H $DISPLAY_HEIGHT \
        -r $DISPLAY_REFRESH \
        --rt \
        -f \
        --steam \
        --adaptive-sync \
        --expose-wayland \
        --backend $GAMESCOPE_BACKEND \
        -- steam -bigpicture &
    STEAM_PID=$!
}

# Start services
start_sunshine
start_steam

# Wait for either process to exit
wait $STEAM_PID 