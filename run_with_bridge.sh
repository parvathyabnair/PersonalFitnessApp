#!/bin/bash
# Helper script to launch the Python Wearable Bluetooth Bridge and Clickable Desktop

echo "Starting Wearable Bluetooth Backend Bridge (Xiaomi Band 9 / Gadgetbridge)..."
python3 backend/bridge.py &
BRIDGE_PID=$!

echo "Bridge running with PID $BRIDGE_PID"
echo "Launching Personal Fitness App on Desktop..."

clickable desktop

# When Clickable desktop closes, terminate the background bridge
kill $BRIDGE_PID 2>/dev/null
echo "Bridge stopped."
