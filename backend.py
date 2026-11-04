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
LOG_FILE = os.path.join(CONFIG_DIR, "backend.log")

def log(msg):
    try:
        os.makedirs(CONFIG_DIR, exist_ok=True)
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {msg}\n")
    except Exception:
        pass

def schedule_notification(seconds, title, message):
    try:
        os.makedirs(CONFIG_DIR, exist_ok=True)
        token = str(int(time.time() * 1000))
        with open(STATE_FILE, "w", encoding="utf-8") as f:
            json.dump({"token": token, "active": True}, f)

        log(f"schedule_notification: delay={seconds}s, title={title}, token={token}")

        # Attempt 1: systemd-run --user (outside app's transient cgroup slice)
        started = False
        try:
            subprocess.Popen([
                "systemd-run", "--user", "--unit=personalfitnessapp-reminder",
                sys.executable, SCHEDULER_SCRIPT, str(seconds), title, message, token
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            started = True
            log("systemd-run --user spawned")
        except Exception as se:
            log(f"systemd-run failed or blocked: {se}")

        # Attempt 2: Detached subprocess fallback
        if not started:
            subprocess.Popen([
                sys.executable, SCHEDULER_SCRIPT, str(seconds), title, message, token
            ], start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            log("subprocess.Popen detached spawned")

        return True
    except Exception as e:
        log(f"schedule_notification exception: {e}")
        sys.stderr.write(f"schedule_notification error: {e}\n")
        return False

def cancel_notification():
    try:
        os.makedirs(CONFIG_DIR, exist_ok=True)
        with open(STATE_FILE, "w", encoding="utf-8") as f:
            json.dump({"token": "", "active": False}, f)
        log("cancel_notification completed")
        return True
    except Exception as e:
        log(f"cancel_notification exception: {e}")
        sys.stderr.write(f"cancel_notification error: {e}\n")
        return False

def dispatch_now(title, message):
    try:
        log(f"dispatch_now called: {title}")
        subprocess.Popen([
            sys.executable, DISPATCHER_SCRIPT, title, message
        ], start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except Exception as e:
        log(f"dispatch_now exception: {e}")
        sys.stderr.write(f"dispatch_now error: {e}\n")
        return False

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        print("Backend test OK")
