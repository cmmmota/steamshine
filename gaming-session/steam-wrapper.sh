#!/bin/bash
# Steam Wrapper for logging and environment verification
set -x

# Ensure we use the gamescope socket
export WAYLAND_DISPLAY=gamescope-0

# Force AMD RADV driver and prevent llvmpipe fallback
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json:/usr/share/vulkan/icd.d/radeon_icd.i686.json

# Suppress modifier issues for RDNA4/mesa-git stability in nested compositors
export WLR_DRM_NO_MODIFIERS=1

# --- Steam Runtime Workarounds ---
# Force Steam to use host libraries (Mesa-git) instead of bundled ones
export STEAM_RUNTIME_PREFER_HOST_LIBRARIES=1

# Prevent Pressure Vessel from trying to create user namespaces (often fails in Docker/K8s)
export PRESSURE_VESSEL_NO_NAMESPACE=1
export PRESSURE_VESSEL_SHARE_HOME=1
# ---------------------------------

echo "--- Steam Wrapper Started at $(date) ---"
echo "USER: $(whoami)"
echo "DISPLAY: $DISPLAY"
echo "WAYLAND_DISPLAY: $WAYLAND_DISPLAY"
echo "DBUS_SESSION_BUS_ADDRESS: $DBUS_SESSION_BUS_ADDRESS"
echo "XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
echo "VK_ICD_FILENAMES: $VK_ICD_FILENAMES"

echo "Available ICD files:"
ls -l /usr/share/vulkan/icd.d/

# Wait for Gamescope socket to be ready
echo "Waiting for Gamescope socket: $WAYLAND_DISPLAY in $XDG_RUNTIME_DIR..."
for i in {1..20}; do
    if [ -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]; then
        echo "Gamescope socket found!"
        ls -la "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
        break
    fi
    echo "Socket not found, waiting (attempt $i)..."
    sleep 1
done

# Verify D-Bus
if dbus-send --session --dest=org.freedesktop.DBus --type=method_call --print-reply /org/freedesktop/DBus org.freedesktop.DBus.ListNames > /dev/null 2>&1; then
    echo "D-Bus session bus is reachable."
else
    echo "WARNING: D-Bus session bus is NOT reachable. Attempting to start one..."
    # If we are in a sub-shell where DBUS_SESSION_BUS_ADDRESS is lost, try to find it
    if [ -f /tmp/dbus-session.env ]; then
        source /tmp/dbus-session.env
    fi
fi

# Show Vulkan info for debugging
vulkaninfo --summary || echo "vulkaninfo failed"

# Steam handles update-restarts by exiting and needing to be called again.
# We loop here to keep Gamescope alive during the update transitions.
while true; do
    echo "--- Launching Steam at $(date) ---"
    steam -bigpicture "$@" 2>&1 | tee -a /tmp/steam.log
    
    EXIT_CODE=$?
    echo "Steam exited with code $EXIT_CODE"
    
    # Code 0 (Updater finished) or 42 (explicit restart) means we should launch again.
    if [ $EXIT_CODE -eq 0 ] || [ $EXIT_CODE -eq 42 ]; then
        echo "Restarting Steam (Update/Restart requested)..."
        sleep 2
    else
        echo "Steam exited with error $EXIT_CODE. Keeping container alive for 30s for logs..."
        sleep 30
        exit $EXIT_CODE
    fi
done
