#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Background Reminder Daemon for Personal Fitness App on Ubuntu Touch.
Runs persistently in the user session to monitor hydration reminder schedules
and dispatch native system notifications even when the main app is closed or minimized.
Also exposes a localhost HTTP endpoint on port 45454 for instant notifications from QML.
"""
import os
import sys
import time
import json
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler
import configparser

# Import dispatcher
SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

try:
    import notify_dispatcher
except ImportError:
    import importlib.util
    spec = importlib.util.spec_from_file_location("notify_dispatcher", os.path.join(SCRIPT_DIR, "notify-dispatcher.py"))
    notify_dispatcher = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(notify_dispatcher)

PORT = 45454
CONFIG_DIR = os.path.expanduser("~/.config/personalfitnessapp.parvathy")
CONFIG_FILE_PRIMARY = os.path.join(CONFIG_DIR, "personalfitnessapp.parvathy.conf")
CONFIG_FILE_SECONDARY = os.path.join(CONFIG_DIR, "personalfitnessapp.conf")

class NotificationRequestHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == "/notify" or self.path == "/":
            content_length = int(self.headers.get('Content-Length', 0))
            body_data = self.rfile.read(content_length) if content_length > 0 else b"{}"
            try:
                payload = json.loads(body_data.decode('utf-8'))
            except Exception:
                payload = {}

            summary = payload.get("summary", "Time to Hydrate!")
            body = payload.get("body", "Take a refreshing drink of water to keep your hydration on track.")
            icon = payload.get("icon", "assets/logo.png")

            # Dispatch system drawer notification
            notify_dispatcher.dispatch(summary, body, icon)

            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"status":"ok"}')
        else:
            self.send_response(404)
            self.end_headers()

    def do_GET(self):
        if self.path == "/ping":
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain')
            self.end_headers()
            self.wfile.write(b"pong")
        else:
            self.send_response(200)
            self.end_headers()

    def log_message(self, format, *args):
        # Silence standard HTTP access logging
        pass

def run_http_server():
    try:
        server = HTTPServer(('127.0.0.1', PORT), NotificationRequestHandler)
        server.serve_forever()
    except Exception as e:
        sys.stderr.write(f"HTTP Server stopped or port busy: {e}\n")

def get_config_path():
    if os.path.exists(CONFIG_FILE_PRIMARY):
        return CONFIG_FILE_PRIMARY
    if os.path.exists(CONFIG_FILE_SECONDARY):
        return CONFIG_FILE_SECONDARY
    return CONFIG_FILE_PRIMARY

def monitor_reminders():
    while True:
        try:
            config_path = get_config_path()
            if os.path.exists(config_path):
                config = configparser.ConfigParser(interpolation=None)
                config.read(config_path, encoding='utf-8')

                section_name = None
                for candidate in ["TimelyReminder", "timelyreminder"]:
                    if config.has_section(candidate):
                        section_name = candidate
                        break

                if section_name:
                    sec = config[section_name]
                    is_active = sec.get("savedActive", "false").lower() == "true"
                    is_paused = sec.get("savedPaused", "false").lower() == "true"

                    target_str = sec.get("savedTargetTimestamp", "0")
                    try:
                        target_ts = float(target_str)
                    except ValueError:
                        target_ts = 0.0

                    interval_str = sec.get("savedIntervalSeconds", "2700")
                    try:
                        interval_sec = int(interval_str)
                    except ValueError:
                        interval_sec = 2700

                    title = sec.get("savedTitle", "Time to Hydrate!")
                    # Strip any surrounding quotes stored by Qt QSettings
                    if (title.startswith('"') and title.endswith('"')) or (title.startswith("'") and title.endswith("'")):
                        title = title[1:-1]

                    message = sec.get("savedMessage", "Take a refreshing drink of water to keep your hydration on track.")
                    if (message.startswith('"') and message.endswith('"')) or (message.startswith("'") and message.endswith("'")):
                        message = message[1:-1]

                    repeat = sec.get("savedRepeat", "true").lower() == "true"

                    now_ms = time.time() * 1000.0

                    if is_active and not is_paused and target_ts > 0:
                        if now_ms >= target_ts:
                            # Time reached! Dispatch system drawer notification
                            notify_dispatcher.dispatch(title, message, "assets/logo.png")

                            # Update configuration for next interval or deactivate
                            if repeat:
                                new_target = now_ms + (interval_sec * 1000.0)
                                config.set(section_name, "savedTargetTimestamp", str(int(new_target)))
                                config.set(section_name, "savedSecondsLeft", str(interval_sec))
                            else:
                                config.set(section_name, "savedActive", "false")
                                config.set(section_name, "savedTargetTimestamp", "0")
                                config.set(section_name, "savedSecondsLeft", "0")

                            with open(config_path, 'w', encoding='utf-8') as f:
                                config.write(f)
        except Exception as e:
            sys.stderr.write(f"Reminder loop error: {e}\n")

        time.sleep(2.5)

def main():
    # Start HTTP server thread for instant local notifications
    t = threading.Thread(target=run_http_server, daemon=True)
    t.start()

    # Run reminder schedule monitor loop in main thread
    monitor_reminders()

if __name__ == "__main__":
    main()
