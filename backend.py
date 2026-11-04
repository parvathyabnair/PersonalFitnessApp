#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Python Backend for Personal Fitness App.
Provides invokable functions to QML (via PyOtherSide) to
schedule detached background notifications and ensure the reminder daemon is active.
"""
import sys
import os
import time
import json
import subprocess

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
if not os.path.exists(os.path.join(SCRIPT_DIR, "daemon.py")):
    SCRIPT_DIR = os.getcwd()

DAEMON_SCRIPT = os.path.join(SCRIPT_DIR, "daemon.py")
SCHEDULER_SCRIPT = os.path.join(SCRIPT_DIR, "scheduled-notification.py")
DISPATCHER_SCRIPT = os.path.join(SCRIPT_DIR, "notify-dispatcher.py")

CONFIG_DIR = os.path.expanduser("~/.config/personalfitnessapp.parvathy")
STATE_FILE = os.path.join(CONFIG_DIR, "scheduled_reminder.json")
TOKEN_FILE = os.path.join(CONFIG_DIR, "push_token.txt")
PID_FILE = os.path.expanduser("~/.personalfitnessapp_daemon.pid")

def log(msg):
    try:
        os.makedirs(CONFIG_DIR, exist_ok=True)
        with open(os.path.join(CONFIG_DIR, "backend.log"), "a", encoding="utf-8") as f:
            f.write(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {msg}\n")
    except Exception:
        pass

def save_token(token):
    try:
        os.makedirs(CONFIG_DIR, exist_ok=True)
        with open(TOKEN_FILE, "w", encoding="utf-8") as f:
            f.write(str(token).strip())
        log(f"Push token saved: {str(token)[:15]}...")
        return True
    except Exception as e:
        log(f"save_token exception: {e}")
        return False

def ensure_daemon():
    try:
        # Check if daemon PID is active
        if os.path.exists(PID_FILE):
            try:
                with open(PID_FILE, 'r') as f:
                    pid = int(f.read().strip())
                os.kill(pid, 0)
                log(f"Daemon already running with PID {pid}")
                return True
            except Exception:
                try: os.unlink(PID_FILE)
                except Exception: pass

        started = False
        try:
            subprocess.Popen([
                "systemd-run", "--user", "--unit=personalfitnessapp-daemon",
                sys.executable, DAEMON_SCRIPT
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            started = True
            log("Started daemon via systemd-run --user")
        except Exception:
            pass

        if not started:
            subprocess.Popen([
                sys.executable, DAEMON_SCRIPT
            ], start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            log("Started daemon via detached subprocess")
        return True
    except Exception as e:
        log(f"ensure_daemon error: {e}")
        return False

def schedule_notification(seconds, title, message):
    try:
        os.makedirs(CONFIG_DIR, exist_ok=True)
        now_ms = time.time() * 1000.0
        target_ts = now_ms + (float(seconds) * 1000.0)

        with open(STATE_FILE, "w", encoding="utf-8") as f:
            json.dump({
                "active": True,
                "target_ts": target_ts,
                "interval_sec": int(seconds),
                "title": title,
                "message": message,
                "repeat": True
            }, f)

        log(f"schedule_notification: {seconds}s, target: {target_ts}")

        # Ensure persistent daemon is running
        ensure_daemon()

        # Detached fallback sleeper
        subprocess.Popen([
            sys.executable, SCHEDULER_SCRIPT, str(seconds), title, message, str(int(now_ms))
        ], start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        return True
    except Exception as e:
        log(f"schedule_notification exception: {e}")
        return False

def cancel_notification():
    try:
        os.makedirs(CONFIG_DIR, exist_ok=True)
        with open(STATE_FILE, "w", encoding="utf-8") as f:
            json.dump({"active": False, "target_ts": 0.0}, f)
        log("cancel_notification completed")
        return True
    except Exception as e:
        log(f"cancel_notification exception: {e}")
        return False

def dispatch_now(title, message):
    try:
        subprocess.Popen([
            sys.executable, DISPATCHER_SCRIPT, title, message
        ], start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except Exception as e:
        log(f"dispatch_now exception: {e}")
        return False

if __name__ == "__main__":
    ensure_daemon()
    print("Backend test OK")
