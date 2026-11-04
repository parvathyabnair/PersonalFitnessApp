#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Background Reminder Daemon for Personal Fitness App on Ubuntu Touch (Lomiri).
Monitors hydration reminder schedules, holds repowerd wakelock/wakeups across sleep,
and dispatches native system notifications even when the main app is closed or minimized.
"""

import sys
import os
import time
import json
import signal
import traceback
import configparser
from pathlib import Path
from datetime import datetime, timezone

APP_PKG = "personalfitnessapp.parvathy"
APP_HOOK = "personalfitnessapp"
APP_ID = f"{APP_PKG}_{APP_HOOK}"
APP_VERSION = "1.0.0"
APP_ID_WITH_VERSION = f"{APP_ID}_{APP_VERSION}"

CONFIG_DIR = Path.home() / ".config" / APP_PKG
STATE_FILE = CONFIG_DIR / "scheduled_reminder.json"
CONF_FILE_PRIMARY = CONFIG_DIR / f"{APP_PKG}.conf"
CONF_FILE_SECONDARY = CONFIG_DIR / "personalfitnessapp.conf"
TOKEN_FILE = CONFIG_DIR / "push_token.txt"
PID_FILE = Path.home() / ".personalfitnessapp_daemon.pid"
HEARTBEAT_FILE = Path.home() / ".personalfitnessapp_daemon_heartbeat"
LOG_FILE = CONFIG_DIR / "daemon.log"
SETUP_NEEDED_FILE = Path.home() / ".personalfitnessapp_needs_setup"

MISSING_DEPS = []
SETUP_INSTRUCTIONS = """
===============================================
MISSING DEPENDENCIES FOR PUSH NOTIFICATIONS
===============================================
To enable system notifications, run via adb:
  sudo apt update
  sudo apt install python3-dbus python3-gi gir1.2-glib-2.0
===============================================
"""

try:
    from dbus.mainloop.glib import DBusGMainLoop
    import dbus
except ImportError as e:
    MISSING_DEPS.append(f"python3-dbus ({e})")

try:
    from gi.repository import GLib
except ImportError as e:
    MISSING_DEPS.append(f"python3-gi / gir1.2-glib-2.0 ({e})")

if MISSING_DEPS:
    try:
        CONFIG_DIR.mkdir(parents=True, exist_ok=True)
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(f"FATAL: Missing dependencies: {', '.join(MISSING_DEPS)}\n{SETUP_INSTRUCTIONS}\n")
        SETUP_NEEDED_FILE.write_text('\n'.join(MISSING_DEPS))
    except Exception:
        pass
    print(f"Missing dependencies: {', '.join(MISSING_DEPS)}", file=sys.stderr)
    sys.exit(1)

# Remove setup needed file if dependencies are available
if SETUP_NEEDED_FILE.exists():
    try:
        SETUP_NEEDED_FILE.unlink()
    except Exception:
        pass

def log(msg):
    try:
        CONFIG_DIR.mkdir(parents=True, exist_ok=True)
        ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(f"[{ts}] [DAEMON] {msg}\n")
    except Exception:
        pass

class FitnessReminderDaemon:
    def __init__(self):
        self.running = True
        self.loop = None
        self.bus = None
        self.system_bus = None
        self.notification_interface = None
        self.wakelock_cookie = None
        self.script_dir = Path(__file__).resolve().parent
        self.icon_path = str(self.script_dir / "assets" / "logo.png")
        if not os.path.exists(self.icon_path):
            self.icon_path = "assets/logo.png"

        self._init_dbus()
        self._write_pid_file()
        self._setup_signal_handlers()
        self._protect_from_oom()
        self._request_wakelock()
        self._setup_suspend_handler()

    def _init_dbus(self, max_retries=5, retry_delay=2):
        if "DBUS_SESSION_BUS_ADDRESS" not in os.environ:
            try:
                uid = os.getuid()
                bus_path = f"/run/user/{uid}/bus"
                if os.path.exists(bus_path):
                    os.environ["DBUS_SESSION_BUS_ADDRESS"] = f"unix:path={bus_path}"
                    log(f"Auto-detected DBus address: {os.environ['DBUS_SESSION_BUS_ADDRESS']}")
            except Exception as e:
                log(f"Error auto-detecting DBus: {e}")

        for attempt in range(max_retries):
            try:
                DBusGMainLoop(set_as_default=True)
                self.bus = dbus.SessionBus()
                notify_service = self.bus.get_object('org.freedesktop.Notifications', '/org/freedesktop/Notifications')
                self.notification_interface = dbus.Interface(notify_service, 'org.freedesktop.Notifications')
                log("DBus session interface initialized")
                return
            except Exception as e:
                if attempt < max_retries - 1:
                    time.sleep(retry_delay)
                else:
                    log(f"Failed to init DBus after {max_retries} attempts: {e}")
                    self.notification_interface = None

    def _get_system_bus(self):
        if not self.system_bus:
            try:
                self.system_bus = dbus.SystemBus()
            except Exception as e:
                log(f"Failed to connect to system bus: {e}")
        return self.system_bus

    def _request_wakelock(self):
        try:
            s_bus = self._get_system_bus()
            if s_bus:
                repowerd = s_bus.get_object('com.lomiri.Repowerd', '/com/lomiri/Repowerd')
                repowerd_iface = dbus.Interface(repowerd, 'com.lomiri.Repowerd')
                self.wakelock_cookie = repowerd_iface.requestSysState("personalfitnessapp-daemon", dbus.Int32(1))
                log(f"Wakelock acquired (cookie: {self.wakelock_cookie})")
        except Exception as e:
            log(f"Failed to acquire wakelock: {e}")
            self.wakelock_cookie = None

    def _release_wakelock(self):
        if self.wakelock_cookie:
            try:
                s_bus = self._get_system_bus()
                if s_bus:
                    repowerd = s_bus.get_object('com.lomiri.Repowerd', '/com/lomiri/Repowerd')
                    repowerd_iface = dbus.Interface(repowerd, 'com.lomiri.Repowerd')
                    repowerd_iface.clearSysState(self.wakelock_cookie)
                    log(f"Wakelock released (cookie: {self.wakelock_cookie})")
                    self.wakelock_cookie = None
            except Exception as e:
                log(f"Failed to release wakelock: {e}")

    def _schedule_wakeup(self, delay=60):
        try:
            s_bus = self._get_system_bus()
            if s_bus:
                repowerd = s_bus.get_object('com.lomiri.Repowerd', '/com/lomiri/Repowerd')
                repowerd_iface = dbus.Interface(repowerd, 'com.lomiri.Repowerd')
                wakeup_time = int(time.time()) + max(10, int(delay))
                cookie = repowerd_iface.requestWakeup("personalfitnessapp-reminder", dbus.UInt64(wakeup_time))
                log(f"Scheduled wakeup at {wakeup_time} (cookie: {cookie})")
        except Exception as e:
            log(f"Failed to schedule wakeup: {e}")

    def _protect_from_oom(self):
        try:
            oom_adj_path = f"/proc/{os.getpid()}/oom_score_adj"
            with open(oom_adj_path, 'w') as f:
                f.write('-500')
            log("OOM protection set (-500)")
        except Exception as e:
            log(f"OOM protection skipped: {e}")

    def _setup_suspend_handler(self):
        try:
            s_bus = self._get_system_bus()
            if s_bus:
                s_bus.add_signal_receiver(
                    self._handle_sleep_signal,
                    signal_name='PrepareForSleep',
                    dbus_interface='org.freedesktop.login1.Manager',
                    bus_name='org.freedesktop.login1'
                )
                log("Registered suspend/resume handler")
        except Exception as e:
            log(f"Failed to register suspend handler: {e}")

    def _handle_sleep_signal(self, sleeping):
        if sleeping:
            log("System entering sleep")
        else:
            log("System woke from sleep - refreshing wakelock")
            self._request_wakelock()
            GLib.timeout_add_seconds(2, self._tick)

    def _write_pid_file(self):
        try:
            PID_FILE.write_text(str(os.getpid()))
        except Exception as e:
            log(f"Failed to write PID file: {e}")

    def _cleanup_pid_file(self):
        try:
            if PID_FILE.exists():
                PID_FILE.unlink()
        except Exception:
            pass

    def _setup_signal_handlers(self):
        signal.signal(signal.SIGTERM, self._handle_shutdown)
        signal.signal(signal.SIGINT, self._handle_shutdown)

    def _handle_shutdown(self, signum, frame):
        log(f"Shutdown signal {signum} received, exiting cleanly...")
        self.running = False
        self._release_wakelock()
        self._cleanup_pid_file()
        if self.loop:
            self.loop.quit()

    def send_notification(self, title, message):
        log(f"Sending notification: {title} - {message}")
        notification_sent = False
        action_uri = f"appid://{APP_PKG}/{APP_HOOK}/current-user-version"

        # 1. Dispatch via Postal (Lomiri Push Architecture)
        for postal_obj_path in [
            f"/com/lomiri/Postal/{APP_PKG.replace('.', '_2e')}",
            f"/com/lomiri/Postal/{APP_PKG}",
            "/com/lomiri/Postal/personalfitnessapp"
        ]:
            try:
                postal = self.bus.get_object('com.lomiri.Postal', postal_obj_path)
                postal_iface = dbus.Interface(postal, 'com.lomiri.Postal')

                # Update badge counter
                try:
                    postal_iface.SetCounter(APP_ID_WITH_VERSION, 1, True)
                except Exception:
                    pass

                msg = {
                    "message": {
                        "text": message,
                        "type": "water",
                        "id": 1
                    },
                    "notification": {
                        "tag": f"hydration_{int(time.time())}",
                        "card": {
                            "summary": title,
                            "body": message,
                            "popup": True,
                            "persist": True,
                            "icon": self.icon_path,
                            "actions": [action_uri]
                        },
                        "sound": True,
                        "vibrate": True
                    }
                }
                json_str = json.dumps(msg)

                for target_id in [APP_ID_WITH_VERSION, APP_ID, f"{APP_PKG}_push"]:
                    try:
                        postal_iface.Post(target_id, json_str)
                        log(f"Postal Post succeeded for {target_id} via {postal_obj_path}")
                        notification_sent = True
                        break
                    except Exception as pe:
                        log.debug(f"Postal Post attempt {target_id} failed: {pe}")
                if notification_sent:
                    break
            except Exception as e:
                log.debug(f"Postal object path {postal_obj_path} unavailable: {e}")

        # 2. Dispatch via FreeDesktop Notifications (Lomiri top banner)
        if not notification_sent:
            try:
                if not self.notification_interface:
                    self._init_dbus()
                if self.notification_interface:
                    hints = {
                        "urgency": dbus.Byte(2),
                        "desktop-entry": dbus.String(APP_ID),
                        "x-canonical-snap-decisions": dbus.String("true"),
                        "x-canonical-private-button-tint": dbus.Boolean(True),
                    }
                    actions = ["default", "Open", action_uri, "Drink Water"]
                    self.notification_interface.Notify(
                        "Personal Fitness App",
                        0,
                        self.icon_path,
                        title,
                        message,
                        actions,
                        hints,
                        -1
                    )
                    log(f"Notification sent via Freedesktop: {title}")
                    notification_sent = True
            except Exception as fe:
                log.warning(f"Freedesktop notification failed: {fe}")

        # 3. UBports Push Server HTTP delivery fallback (if token exists)
        if TOKEN_FILE.exists():
            try:
                push_token = TOKEN_FILE.read_text().strip()
                if push_token:
                    import urllib.request
                    expire_on = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime(time.time() + 3600))
                    push_body = {
                        "appid": APP_ID,
                        "token": push_token,
                        "expire_on": expire_on,
                        "data": {
                            "notification": {
                                "card": {
                                    "summary": title,
                                    "body": message,
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
                        data=json.dumps(push_body).encode("utf-8"),
                        headers={"Content-Type": "application/json"}
                    )
                    with urllib.request.urlopen(req, timeout=5) as resp:
                        log(f"UBports Push Server response: {resp.getcode()}")
                        notification_sent = True
            except Exception as ue:
                log.warning(f"UBports Push Server request failed: {ue}")

        return notification_sent

    def _read_reminder_state(self):
        """Reads reminder state from scheduled_reminder.json and Qt QSettings conf file."""
        is_active = False
        target_ts = 0.0
        interval_sec = 2700
        title = "Time to Hydrate!"
        message = "Take a refreshing drink of water to keep your hydration on track."
        repeat = True

        # Check JSON state file first
        if STATE_FILE.exists():
            try:
                with open(STATE_FILE, "r", encoding="utf-8") as f:
                    sdata = json.load(f)
                is_active = bool(sdata.get("active", False))
                target_ts = float(sdata.get("target_ts", 0.0))
                interval_sec = int(sdata.get("interval_sec", 2700))
                title = sdata.get("title", title)
                message = sdata.get("message", message)
                repeat = bool(sdata.get("repeat", True))
                if is_active and target_ts > 0:
                    return is_active, target_ts, title, message, repeat, interval_sec
            except Exception as e:
                log.debug(f"Error reading JSON state: {e}")

        # Check Qt Settings conf file
        conf_path = CONF_FILE_PRIMARY if CONF_FILE_PRIMARY.exists() else (CONF_FILE_SECONDARY if CONF_FILE_SECONDARY.exists() else None)
        if conf_path:
            try:
                config = configparser.ConfigParser(interpolation=None)
                config.read(str(conf_path), encoding='utf-8')
                for sec_name in ["TimelyReminder", "timelyreminder"]:
                    if config.has_section(sec_name):
                        sec = config[sec_name]
                        is_act = sec.get("savedActive", "false").lower() == "true"
                        is_pau = sec.get("savedPaused", "false").lower() == "true"
                        if is_act and not is_pau:
                            is_active = True
                            target_ts = float(sec.get("savedTargetTimestamp", "0"))
                            interval_sec = int(sec.get("savedIntervalSeconds", "2700"))
                            t = sec.get("savedTitle", title).strip('"\'')
                            m = sec.get("savedMessage", message).strip('"\'')
                            if t: title = t
                            if m: message = m
                            repeat = sec.get("savedRepeat", "true").lower() == "true"
                        break
            except Exception as e:
                log.debug(f"Error reading Qt conf file: {e}")

        return is_active, target_ts, title, message, repeat, interval_sec

    def _update_reminder_target(self, new_target, interval_sec):
        # Update JSON state file
        try:
            CONFIG_DIR.mkdir(parents=True, exist_ok=True)
            with open(STATE_FILE, "w", encoding="utf-8") as f:
                json.dump({"active": True, "target_ts": new_target, "interval_sec": interval_sec}, f)
        except Exception:
            pass

        # Update Qt Settings conf file
        conf_path = CONF_FILE_PRIMARY if CONF_FILE_PRIMARY.exists() else (CONF_FILE_SECONDARY if CONF_FILE_SECONDARY.exists() else None)
        if conf_path:
            try:
                config = configparser.ConfigParser(interpolation=None)
                config.read(str(conf_path), encoding='utf-8')
                for sec_name in ["TimelyReminder", "timelyreminder"]:
                    if config.has_section(sec_name):
                        config.set(sec_name, "savedTargetTimestamp", str(int(new_target)))
                        config.set(sec_name, "savedSecondsLeft", str(interval_sec))
                        with open(conf_path, 'w', encoding='utf-8') as f:
                            config.write(f)
                        break
            except Exception:
                pass

    def _mark_reminder_completed(self):
        try:
            with open(STATE_FILE, "w", encoding="utf-8") as f:
                json.dump({"active": False, "target_ts": 0.0}, f)
        except Exception:
            pass

        conf_path = CONF_FILE_PRIMARY if CONF_FILE_PRIMARY.exists() else (CONF_FILE_SECONDARY if CONF_FILE_SECONDARY.exists() else None)
        if conf_path:
            try:
                config = configparser.ConfigParser(interpolation=None)
                config.read(str(conf_path), encoding='utf-8')
                for sec_name in ["TimelyReminder", "timelyreminder"]:
                    if config.has_section(sec_name):
                        config.set(sec_name, "savedActive", "false")
                        config.set(sec_name, "savedTargetTimestamp", "0")
                        config.set(sec_name, "savedSecondsLeft", "0")
                        with open(conf_path, 'w', encoding='utf-8') as f:
                            config.write(f)
                        break
            except Exception:
                pass

    def _tick(self):
        try:
            HEARTBEAT_FILE.write_text(datetime.now(timezone.utc).isoformat())
            is_active, target_ts, title, message, repeat, interval = self._read_reminder_state()

            if is_active and target_ts > 0:
                now_ms = time.time() * 1000.0
                if now_ms >= target_ts:
                    log(f"Reminder target reached ({target_ts}), dispatching notification...")
                    self.send_notification(title, message)
                    if repeat and interval > 0:
                        new_target = now_ms + (interval * 1000.0)
                        self._update_reminder_target(new_target, interval)
                        self._schedule_wakeup(interval)
                    else:
                        self._mark_reminder_completed()
                else:
                    remaining_sec = (target_ts - now_ms) / 1000.0
                    if remaining_sec <= 300:
                        self._schedule_wakeup(remaining_sec)
        except Exception as e:
            log(f"Tick exception: {e}")
        return self.running

    def run(self):
        log(f"Starting FitnessReminderDaemon (PID: {os.getpid()})")
        # Periodic tick every 3 seconds
        GLib.timeout_add_seconds(3, self._tick)

        self.loop = GLib.MainLoop()
        try:
            self.loop.run()
        except KeyboardInterrupt:
            pass
        except Exception as e:
            log(f"MainLoop crash: {e}")

        self._release_wakelock()
        self._cleanup_pid_file()
        log("FitnessReminderDaemon stopped")

def check_already_running():
    if PID_FILE.exists():
        try:
            old_pid = int(PID_FILE.read_text().strip())
            os.kill(old_pid, 0)
            return True, old_pid
        except (ProcessLookupError, ValueError):
            PID_FILE.unlink(missing_ok=True)
        except PermissionError:
            return True, old_pid
    return False, None

def main():
    is_running, pid = check_already_running()
    if is_running:
        log(f"Daemon already running with PID {pid}")
        sys.exit(0)

    daemon = FitnessReminderDaemon()
    daemon.run()

if __name__ == "__main__":
    main()
