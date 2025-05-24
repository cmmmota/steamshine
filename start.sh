#!/bin/bash
set -e

# Start Steam in the background
steam &
STEAM_PID=$!

# Start Sunshine
sunshine &
SUNSHINE_PID=$!

# Only wait for Sunshine to exit, as Steam may restart during updates
wait $SUNSHINE_PID 