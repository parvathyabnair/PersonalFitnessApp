#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Notification Dispatcher for Personal Fitness App on Ubuntu Touch (Lomiri)
Dispatches system drawer notifications through Postal (com.ubuntu.Postal & com.lomiri.Postal)
and FreeDesktop Notifications (org.freedesktop.Notifications).
"""
import sys
import json
import time
import subprocess
import shutil
import os

APP_PKG = "personalfitnessapp.parvathy"
APP_HOOK = "personalfitnessapp"
APP_ID = f"{APP_PKG}_{APP_HOOK}"
OBJECT_SUFFIX = "personalfitnessapp_2eparvathy"

def dispatch(summary="Time to Hydrate!", body="Take a refreshing drink of water to keep your hydration on track.", icon="assets/logo.png"):
    # Resolve absolute icon path if possible
    script_dir = os.path.dirname(os.path.realpath(__file__))
    resolved_icon = icon
    if not os.path.isabs(resolved_icon):
        candidate = os.path.join(script_dir, icon)
        if os.path.exists(candidate):
            resolved_icon = candidate

    payload = {
        "message": summary,
        "notification": {
            "card": {
                "summary": summary,
                "body": body,
                "icon": resolved_icon,
                "popup": True,
                "persist": True,
                "timestamp": int(time.time())
            },
            "sound": True,
            "vibrate": True
        }
    }
    payload_str = json.dumps(payload)

    # 1. Dispatch via com.ubuntu.Postal (both hook targets)
    for hook_target in [f"{APP_PKG}_personalfitnessapp", f"{APP_PKG}_push", APP_PKG]:
        for obj_path in [f"/com/ubuntu/Postal/{OBJECT_SUFFIX}", f"/com/ubuntu/Postal/{OBJECT_SUFFIX}_2epersonalfitnessapp"]:
            try:
                subprocess.run([
                    "gdbus", "call", "--session",
                    "--dest", "com.ubuntu.Postal",
                    "--object-path", obj_path,
                    "--method", "com.ubuntu.Postal.Post",
                    hook_target, payload_str
                ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=2)
            except Exception:
                pass

    # 2. Dispatch via com.lomiri.Postal (Lomiri namespace)
    for hook_target in [f"{APP_PKG}_personalfitnessapp", f"{APP_PKG}_push", APP_PKG]:
        for obj_path in [f"/com/lomiri/Postal/{OBJECT_SUFFIX}", f"/com/lomiri/Postal/{OBJECT_SUFFIX}_2epersonalfitnessapp"]:
            try:
                subprocess.run([
                    "gdbus", "call", "--session",
                    "--dest", "com.lomiri.Postal",
                    "--object-path", obj_path,
                    "--method", "com.lomiri.Postal.Post",
                    hook_target, payload_str
                ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=2)
            except Exception:
                pass

    # 3. Dispatch via org.freedesktop.Notifications (Desktop / Lomiri shell fallback)
    try:
        subprocess.run([
            "gdbus", "call", "--session",
            "--dest", "org.freedesktop.Notifications",
            "--object-path", "/org/freedesktop/Notifications",
            "--method", "org.freedesktop.Notifications.Notify",
            "Personal Fitness App", "0", resolved_icon, summary, body, "[]", "{}", "5000"
        ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=2)
    except Exception:
        pass

    # 4. Dispatch via notify-send if installed
    if shutil.which("notify-send"):
        try:
            subprocess.run([
                "notify-send", "-a", "Personal Fitness App",
                "-i", resolved_icon, summary, body
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=2)
        except Exception:
            pass

if __name__ == "__main__":
    s = sys.argv[1] if len(sys.argv) > 1 else "Time to Hydrate!"
    b = sys.argv[2] if len(sys.argv) > 2 else "Take a refreshing drink of water to keep your hydration on track."
    ic = sys.argv[3] if len(sys.argv) > 3 else "assets/logo.png"
    dispatch(s, b, ic)

