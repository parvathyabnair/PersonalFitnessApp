#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Notification Dispatcher for Personal Fitness App on Ubuntu Touch (Lomiri)
Dispatches system drawer notifications through Postal (com.lomiri.Postal & com.ubuntu.Postal),
FreeDesktop Notifications (org.freedesktop.Notifications), and UBports Push Server.
"""
import sys
import os
import time
import json
import subprocess
import shutil

APP_PKG = "personalfitnessapp.parvathy"
APP_HOOK = "personalfitnessapp"
APP_ID = f"{APP_PKG}_{APP_HOOK}"
OBJECT_SUFFIX = "personalfitnessapp_2eparvathy"
CONFIG_DIR = os.path.expanduser(f"~/.config/{APP_PKG}")
LOG_FILE = os.path.join(CONFIG_DIR, "notify.log")
TOKEN_FILE = os.path.join(CONFIG_DIR, "push_token.txt")

def log(msg):
    try:
        os.makedirs(CONFIG_DIR, exist_ok=True)
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {msg}\n")
    except Exception:
        pass

def dispatch(summary="Time to Hydrate!", body="Take a refreshing drink of water to keep your hydration on track.", icon="assets/logo.png"):
    log(f"dispatch called: summary={summary}, body={body}")
    script_dir = os.path.dirname(os.path.realpath(__file__))
    resolved_icon = icon
    if not os.path.isabs(resolved_icon):
        candidate = os.path.join(script_dir, icon)
        if os.path.exists(candidate):
            resolved_icon = candidate
        else:
            resolved_icon = "notification"

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

    # 1. Dispatch via UBports Push Server if token is available
    if os.path.exists(TOKEN_FILE):
        try:
            with open(TOKEN_FILE, "r", encoding="utf-8") as f:
                push_token = f.read().strip()
            if push_token:
                import urllib.request
                expire_on = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime(time.time() + 3600))
                push_payload = {
                    "appid": APP_ID,
                    "token": push_token,
                    "expire_on": expire_on,
                    "data": {
                        "notification": {
                            "card": {
                                "summary": summary,
                                "body": body,
                                "popup": True,
                                "persist": True
                            },
                            "sound": True,
                            "vibrate": True
                        }
                    }
                }
                req = urllib.request.Request(
                    "https://push.ubports.com/notify",
                    data=json.dumps(push_payload).encode("utf-8"),
                    headers={"Content-Type": "application/json"}
                )
                with urllib.request.urlopen(req, timeout=5) as resp:
                    log(f"UBports Push Server response: {resp.getcode()}")
        except Exception as pe:
            log(f"UBports Push Server error: {pe}")

    # 2. Native D-Bus via gi.repository.Gio (fast, reliable)
    try:
        from gi.repository import Gio, GLib
        connection = Gio.bus_get_sync(Gio.BusType.SESSION, None)

        # 2a. FreeDesktop Notifications
        try:
            connection.call_sync(
                "org.freedesktop.Notifications",
                "/org/freedesktop/Notifications",
                "org.freedesktop.Notifications",
                "Notify",
                GLib.Variant("(susssasa{sv}i)", (
                    "Personal Fitness App",
                    0,
                    resolved_icon,
                    summary,
                    body,
                    [],
                    {},
                    5000
                )),
                None,
                Gio.DBusCallFlags.NONE,
                2000,
                None
            )
            log("Gio: FreeDesktop Notify succeeded")
        except Exception as fe:
            log(f"Gio: FreeDesktop Notify error: {fe}")

        # 2b. Postal (Lomiri & Ubuntu namespaces)
        for bus_name in ["com.lomiri.Postal", "com.ubuntu.Postal"]:
            for path_name in [
                f"/com/lomiri/Postal/{OBJECT_SUFFIX}",
                f"/com/ubuntu/Postal/{OBJECT_SUFFIX}",
                f"/com/lomiri/Postal/{OBJECT_SUFFIX}_2epersonalfitnessapp",
                f"/com/ubuntu/Postal/{OBJECT_SUFFIX}_2epersonalfitnessapp"
            ]:
                for target_id in [APP_ID, f"{APP_PKG}_push", APP_PKG]:
                    try:
                        connection.call_sync(
                            bus_name,
                            path_name,
                            bus_name,
                            "Post",
                            GLib.Variant("(ss)", (target_id, payload_str)),
                            None,
                            Gio.DBusCallFlags.NONE,
                            2000,
                            None
                        )
                        log(f"Gio: Postal {bus_name} at {path_name} for {target_id} succeeded")
                    except Exception:
                        pass
    except Exception as ge:
        log(f"Gio D-Bus connection error: {ge}")

    # 3. Subprocess gdbus fallback
    for bus_name in ["com.lomiri.Postal", "com.ubuntu.Postal"]:
        for path_name in [
            f"/{bus_name.replace('.', '/')}/{OBJECT_SUFFIX}",
            f"/{bus_name.replace('.', '/')}/{OBJECT_SUFFIX}_2epersonalfitnessapp"
        ]:
            for target_id in [APP_ID, f"{APP_PKG}_push", APP_PKG]:
                try:
                    subprocess.run([
                        "gdbus", "call", "--session",
                        "--dest", bus_name,
                        "--object-path", path_name,
                        "--method", f"{bus_name}.Post",
                        target_id, payload_str
                    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=2)
                except Exception:
                    pass

    # 4. notify-send fallback
    if shutil.which("notify-send"):
        try:
            subprocess.run([
                "notify-send", "-a", "Personal Fitness App",
                "-i", resolved_icon, summary, body
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=2)
            log("notify-send executed")
        except Exception as ne:
            log(f"notify-send error: {ne}")

if __name__ == "__main__":
    s = sys.argv[1] if len(sys.argv) > 1 else "Time to Hydrate!"
    b = sys.argv[2] if len(sys.argv) > 2 else "Take a refreshing drink of water to keep your hydration on track."
    ic = sys.argv[3] if len(sys.argv) > 3 else "assets/logo.png"
    dispatch(s, b, ic)
