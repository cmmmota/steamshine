#!/bin/bash
set -e

# Start Steam in the background
steam &
STEAM_PID=$!

# Start Sunshine
sunshine &
SUNSHINE_PID=$!

# Wait for either process to exit
wait $STEAM_PID $SUNSHINE_PID 