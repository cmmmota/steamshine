#!/bin/bash
set -e

# Function to handle shutdown
shutdown() {
    echo "Shutting down..."
    
    # Try to shut down Steam gracefully
    #echo "Shutting down Steam..."
    #steam -shutdown &
    
    # Try to shut down Sunshine gracefully
    echo "Shutting down Sunshine..."
    kill -TERM $SUNSHINE_PID 2>/dev/null || true
    
    # Wait for processes to terminate gracefully (up to 30 seconds)
    for i in {1..30}; do
        if ! kill -0 $SUNSHINE_PID 2>/dev/null && \
           ! kill -0 $STEAM_PID 2>/dev/null && \
           ! kill -0 $WESTON_PID 2>/dev/null; then
            echo "All processes terminated gracefully"
            exit 0
        fi
        sleep 1
    done
    
    # If processes are still running after timeout, try SIGTERM
    echo "Sending SIGTERM to remaining processes..."
    kill -TERM $SUNSHINE_PID 2>/dev/null || true
    kill -TERM $STEAM_PID 2>/dev/null || true
    kill -TERM $WESTON_PID 2>/dev/null || true
    
    # Wait another 10 seconds for SIGTERM to take effect
    for i in {1..10}; do
        if ! kill -0 $SUNSHINE_PID 2>/dev/null && \
           ! kill -0 $STEAM_PID 2>/dev/null && \
           ! kill -0 $WESTON_PID 2>/dev/null; then
            echo "All processes terminated after SIGTERM"
            exit 0
        fi
        sleep 1
    done
    
    # If processes are still running, force kill
    echo "Forcing shutdown after timeout..."
    kill -9 $SUNSHINE_PID 2>/dev/null || true
    kill -9 $STEAM_PID 2>/dev/null || true
    kill -9 $WESTON_PID 2>/dev/null || true
    
    exit 0
}

# Trap SIGTERM and SIGINT
trap shutdown SIGTERM SIGINT

# Start Weston
weston &
WESTON_PID=$!

# Give Weston a moment to initialize
sleep 3

# Start Steam in the background
#steam &
#STEAM_PID=$!

# Start Sunshine
sunshine &
SUNSHINE_PID=$!

# Monitor processes
while true; do
    # Check if critical processes have died
    if ! kill -0 $WESTON_PID 2>/dev/null; then
        echo "Weston has died"
        shutdown
    fi
    
    if ! kill -0 $SUNSHINE_PID 2>/dev/null; then
        echo "Sunshine has died"
        shutdown
    fi
    
    sleep 1
done 