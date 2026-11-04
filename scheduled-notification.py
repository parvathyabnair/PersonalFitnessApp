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

CONFIG_DIR = os.path.expanduser("~/.config/personalfitnessapp.parvathy")
LOG_FILE = os.path.join(CONFIG_DIR, "scheduler.log")

def log(msg):
    try:
        os.makedirs(CONFIG_DIR, exist_ok=True)
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {msg}\n")
    except Exception:
        pass

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

    state_file = os.path.join(CONFIG_DIR, "scheduled_reminder.json")
    log(f"Worker started: delay={delay}s, token={token}")

    # Sleep for scheduled delay (e.g. 120 seconds)
    if delay > 0:
        time.sleep(delay)

    # Verify if reminder is still active and token matches
    if os.path.exists(state_file):
        try:
            with open(state_file, "r", encoding="utf-8") as f:
                data = json.load(f)
            if not data.get("active") or str(data.get("token")) != str(token):
                log(f"Timer cancelled or superseded: active={data.get('active')}, token={data.get('token')}")
                sys.exit(0)
        except Exception as e:
            log(f"Error reading reminder state: {e}")

    # Mark as completed in state file
    try:
        os.makedirs(CONFIG_DIR, exist_ok=True)
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
        log(f"Triggering dispatcher: {dispatcher}")
        subprocess.run([sys.executable, dispatcher, title, message])
    else:
        log("notify-dispatcher.py not found!")

if __name__ == "__main__":
    main()
