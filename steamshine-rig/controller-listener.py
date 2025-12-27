#!/usr/bin/env python3
import evdev
import subprocess
import os
import time
import glob

# Combo: Guide (BTN_MODE) + Start (BTN_START)
# Note: Codes might vary slightly depending on controller, but these are standard for Xbox/PS controllers.
COMBO = {evdev.ecodes.BTN_MODE, evdev.ecodes.BTN_START}

def find_controllers():
    devices = [evdev.InputDevice(path) for path in evdev.list_devices()]
    # Filter for devices that look like gamepads (have buttons and axes)
    return [d for d in devices if evdev.ecodes.EV_KEY in d.capabilities() and evdev.ecodes.BTN_GAMEPAD in d.capabilities(absinfo=False)[evdev.ecodes.EV_KEY]]

def monitor_device(device):
    active_buttons = set()
    print(f"Monitoring {device.name} ({device.path})")
    try:
        for event in device.read_loop():
            if event.type == evdev.ecodes.EV_KEY:
                if event.value == 1: # Press
                    active_buttons.add(event.code)
                elif event.value == 0: # Release
                    active_buttons.discard(event.code)
                
                if COMBO.issubset(active_buttons):
                    print("Combo detected! Launching Steam...")
                    subprocess.run(["hyprctl", "dispatch", "exec", "steam -gamepadui -steamos3"], check=False)
                    # Small cool down to avoid multiple launches
                    time.sleep(2)
                    active_buttons.clear()
    except (OSError, evdev.IOError):
        print(f"Device {device.path} disconnected.")

def main():
    print("Starting Steam Controller Listener...")
    monitored_paths = set()
    
    while True:
        controllers = find_controllers()
        for controller in controllers:
            if controller.path not in monitored_paths:
                monitored_paths.add(controller.path)
                # In a real tool we might want threading, but here we just want a simple loop
                # Since we typically only have one controller for the user, we block or use async.
                # Let's keep it simple for now and monitor the first one found or use a simpler poll.
                monitor_device(controller)
                monitored_paths.discard(controller.path)
        
        time.sleep(5)

if __name__ == "__main__":
    main()
