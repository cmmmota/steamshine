#!/bin/bash

# ensure /dev/uinput is usable even if the host rule is missing
sudo chgrp input /dev/uinput || true
sudo chmod g+rw /dev/uinput || true

export XDG_RUNTIME_DIR=/tmp/xdg-runtime
mkdir -p $XDG_RUNTIME_DIR
chmod 711 $XDG_RUNTIME_DIR

# Resolution/refresh defaults (overridable via env passed to the container)
export DISPLAY_WIDTH="${DISPLAY_WIDTH:-2560}"
export DISPLAY_HEIGHT="${DISPLAY_HEIGHT:-1440}"
export DISPLAY_REFRESH_RATE="${DISPLAY_REFRESH_RATE:-60}"

# Gamescope will act as our minimal compositor
# No additional wlroots variables required

sudo ldconfig

# Function to start Sunshine with appropriate GPU settings
start_sunshine() {
    # Gamescope's fixed display name
    export WAYLAND_DISPLAY="gamescope-0"
    # give gamescope a moment to finish socket creation
    sleep 1
    # Start Sunshine in the background
    sunshine &
    SUNSHINE_PID=$!
}

start_gamescope() {
    # Start seatd so libinput can access /dev/input and /dev/uinput
    sudo /usr/bin/seatd -u steamshine -g input -l info &
    SEATD_PID=$!
    trap 'kill $SEATD_PID 2>/dev/null' EXIT

    # Start Steam Big-Picture inside headless Gamescope
    dbus-run-session \
    gamescope \
        --backend headless \
        --expose-wayland \
        -W "$DISPLAY_WIDTH" -H "$DISPLAY_HEIGHT" \
        -r "$DISPLAY_REFRESH_RATE" \
        --rt \
        -- steam -tenfoot &
    GAMESCOPE_PID=$!

    # Let Gamescope set up its WAYLAND_DISPLAY env var
    sleep 2                    # give Gamescope time to initialise

    # immediately after launching gamescope …
    export WAYLAND_DISPLAY=gamescope-0        # <- Gamescope's fixed socket name
    sleep 2
}

# Start compositor (Gamescope) and Sunshine
start_gamescope
start_sunshine

# Wait for sunshine to exit (or propagate any signal)
wait "$SUNSHINE_PID"