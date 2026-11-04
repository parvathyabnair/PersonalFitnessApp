#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Scheduled Notification Worker for Personal Fitness App on Ubuntu Touch.
Runs in a detached process, sleeps for the specified delay, checks if the reminder
is still valid/active, and then dispatches the notification to the Lomiri system drawer.
"""
import sys
import os
import time
import json
import subprocess

def main():
    if len(sys.argv) < 5:
        sys.exit(0)

    try:
        delay = float(sys.argv[1])
    except ValueError:
        delay = 0.0

    title = sys.argv[2]
    message = sys.argv[3]
    token = sys.argv[4]

    config_dir = os.path.expanduser("~/.config/personalfitnessapp.parvathy")
    state_file = os.path.join(config_dir, "scheduled_reminder.json")

    # Sleep for scheduled delay (e.g. 120 seconds)
    if delay > 0:
        time.sleep(delay)

    # Verify if reminder is still active and token matches
    if os.path.exists(state_file):
        try:
            with open(state_file, "r", encoding="utf-8") as f:
                data = json.load(f)
            if not data.get("active") or str(data.get("token")) != str(token):
                # Timer was cancelled or superseded by a newer timer
                sys.exit(0)
        except Exception as e:
            sys.stderr.write(f"Error reading reminder state: {e}\n")

    # Mark as completed in state file
    try:
        os.makedirs(config_dir, exist_ok=True)
        with open(state_file, "w", encoding="utf-8") as f:
            json.dump({"token": "", "active": False}, f)
    except Exception:
        pass

    # Find notify-dispatcher.py
    script_dir = os.path.dirname(os.path.realpath(__file__))
    dispatcher = os.path.join(script_dir, "notify-dispatcher.py")
    if not os.path.exists(dispatcher):
        candidate = os.path.join(os.getcwd(), "notify-dispatcher.py")
        if os.path.exists(candidate):
            dispatcher = candidate

    if os.path.exists(dispatcher):
        subprocess.run([sys.executable, dispatcher, title, message])

if __name__ == "__main__":
    main()

