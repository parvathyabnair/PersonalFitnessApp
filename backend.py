#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Python Backend for Personal Fitness App.
Provides invokable functions to QML (via PyOtherSide or direct scripts) to
schedule detached background notifications and dispatch immediate alerts.
"""
import sys
import os
import time
import json
import subprocess

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
if not os.path.exists(os.path.join(SCRIPT_DIR, "scheduled-notification.py")):
    SCRIPT_DIR = os.getcwd()

SCHEDULER_SCRIPT = os.path.join(SCRIPT_DIR, "scheduled-notification.py")
DISPATCHER_SCRIPT = os.path.join(SCRIPT_DIR, "notify-dispatcher.py")
CONFIG_DIR = os.path.expanduser("~/.config/personalfitnessapp.parvathy")
STATE_FILE = os.path.join(CONFIG_DIR, "scheduled_reminder.json")

def schedule_notification(seconds, title, message):
    try:
        os.makedirs(CONFIG_DIR, exist_ok=True)
        token = str(int(time.time() * 1000))
        with open(STATE_FILE, "w", encoding="utf-8") as f:
            json.dump({"token": token, "active": True}, f)

        # Spawn detached process with start_new_session=True
        # This keeps the sleeper process alive even after the main app is closed!
        subprocess.Popen([
            sys.executable, SCHEDULER_SCRIPT, str(seconds), title, message, token
        ], start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except Exception as e:
        sys.stderr.write(f"schedule_notification error: {e}\n")
        return False

def cancel_notification():
    try:
        os.makedirs(CONFIG_DIR, exist_ok=True)
        with open(STATE_FILE, "w", encoding="utf-8") as f:
            json.dump({"token": "", "active": False}, f)
        return True
    except Exception as e:
        sys.stderr.write(f"cancel_notification error: {e}\n")
        return False

def dispatch_now(title, message):
    try:
        subprocess.Popen([
            sys.executable, DISPATCHER_SCRIPT, title, message
        ], start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except Exception as e:
        sys.stderr.write(f"dispatch_now error: {e}\n")
        return False

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        print("Backend test OK")

