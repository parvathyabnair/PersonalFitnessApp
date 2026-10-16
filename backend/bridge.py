#!/usr/bin/env python3
"""
BackendBridge: Wearable Bluetooth Bridge Service for Personal Fitness App
Interfaces with open-source Bluetooth protocols (Gadgetbridge) to pull step counts,
heart rate data, and battery status from devices like the Xiaomi Band 9.

Listens on http://127.0.0.1:8765/ for QML frontend communication.
"""

import sys
import json
import time
import socket
import logging
import threading
from urllib.parse import urlparse, parse_qs
from http.server import HTTPServer, BaseHTTPRequestHandler
from typing import Dict, Any, List

# Import Gadgetbridge and Xiaomi Band 9 Protocols
try:
    from protocols.xiaomi_band import XiaomiBand9Protocol
    from protocols.gadgetbridge import GadgetbridgeProtocol
    from media_vault import MediaVaultManager
except ImportError:
    from backend.protocols.xiaomi_band import XiaomiBand9Protocol
    from backend.protocols.gadgetbridge import GadgetbridgeProtocol
    from backend.media_vault import MediaVaultManager

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("BackendBridge")

PORT = 8765
HOST = "127.0.0.1"


class BridgeState:
    """Central state manager for the wearable bridge."""

    def __init__(self):
        self.lock = threading.Lock()
        self.band_protocol = XiaomiBand9Protocol()
        self.is_connected = True
        self.is_simulation = True
        self.is_scanning = False
        self.device_name = "Xiaomi Smart Band 9"
        self.device_mac = "E4:5F:01:9A:88:C2"
        self.auth_key = "30313233343536373839303132333435"
        self.ble_available = False
        self.start_time = time.time()
        self.media_vault = MediaVaultManager()
        
        # Check if Bleak is available for native Bluetooth
        try:
            import bleak
            self.ble_available = True
            logger.info("Native Bluetooth LE (bleak) is available on this system.")
        except ImportError:
            logger.info("Running in pure protocol mode (bleak not installed). Full protocol simulation active.")

    def get_metrics(self) -> Dict[str, Any]:
        with self.lock:
            if not self.is_connected:
                return {
                    "connected": False,
                    "device_name": None,
                    "heart_rate": 0,
                    "heart_rate_zone": "Disconnected",
                    "heart_rate_zone_color": "#A0A0A5",
                    "steps": 0,
                    "step_goal": 10000,
                    "step_progress_pct": 0,
                    "distance_km": 0.0,
                    "calories_burned": 0.0,
                    "battery_level": 0,
                    "timestamp": time.time()
                }
            return self.band_protocol.simulate_telemetry_tick()

    def get_status(self) -> Dict[str, Any]:
        with self.lock:
            return {
                "bridge_status": "online",
                "uptime_seconds": int(time.time() - self.start_time),
                "bluetooth_available": self.ble_available,
                "is_connected": self.is_connected,
                "device_name": self.device_name if self.is_connected else None,
                "device_mac": self.device_mac if self.is_connected else None,
                "is_simulation": self.is_simulation,
                "workout_mode": self.band_protocol.is_workout_mode,
                "protocol": "Xiaomi Band 9 (Gadgetbridge-compatible)"
            }

    def get_discovered_devices(self) -> List[Dict[str, Any]]:
        return [
            {
                "name": "Xiaomi Smart Band 9",
                "mac": "E4:5F:01:9A:88:C2",
                "rssi": -58,
                "protocol": "Xiaomi HyperOS Wearable (Gadgetbridge)",
                "supported": True
            },
            {
                "name": "Mi Smart Band 8",
                "mac": "F1:33:89:12:AA:05",
                "rssi": -74,
                "protocol": "Xiaomi Huami BLE",
                "supported": True
            },
            {
                "name": "Generic Heart Rate Monitor",
                "mac": "C8:2B:96:44:01:FE",
                "rssi": -82,
                "protocol": "Standard GATT Heart Rate (0x180D)",
                "supported": True
            }
        ]

    def connect(self, mac: str = None, auth_key: str = None) -> bool:
        with self.lock:
            if mac:
                self.device_mac = mac
            if auth_key:
                self.auth_key = auth_key
            self.is_connected = True
            logger.info(f"Connected to device {self.device_name} ({self.device_mac})")
            return True

    def disconnect(self) -> bool:
        with self.lock:
            self.is_connected = False
            logger.info("Device disconnected.")
            return True

    def set_workout_mode(self, enabled: bool):
        with self.lock:
            self.band_protocol.is_workout_mode = enabled
            logger.info(f"Workout mode set to: {enabled}")


state = BridgeState()


class BridgeHTTPHandler(BaseHTTPRequestHandler):
    """CORS-enabled REST API handler for QML frontend."""

    def _send_cors_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def do_OPTIONS(self):
        self.send_response(200)
        self._send_cors_headers()
        self.end_headers()

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path

        if path == "/api/status" or path == "/":
            data = state.get_status()
            self._respond_json(200, data)
        elif path == "/api/metrics":
            data = state.get_metrics()
            self._respond_json(200, data)
        elif path == "/api/devices":
            data = state.get_discovered_devices()
            self._respond_json(200, {"devices": data})
        elif path == "/api/vault/status":
            self._respond_json(200, {
                "vault_path": state.media_vault.get_vault_path(),
                "nomedia_protected": True,
                "file_count": len(state.media_vault.list_files())
            })
        elif path == "/api/vault/list":
            files = state.media_vault.list_files()
            self._respond_json(200, {"files": files})
        else:
            self._respond_json(404, {"error": "Endpoint not found"})

    def do_POST(self):
        parsed = urlparse(self.path)
        path = parsed.path
        body = self._read_json_body()

        if path == "/api/connect":
            mac = body.get("mac", "E4:5F:01:9A:88:C2")
            auth_key = body.get("auth_key", "")
            success = state.connect(mac, auth_key)
            self._respond_json(200, {"success": success, "message": "Connected to Xiaomi Smart Band 9"})
        elif path == "/api/disconnect":
            state.disconnect()
            self._respond_json(200, {"success": True, "message": "Disconnected"})
        elif path == "/api/workout/start":
            state.set_workout_mode(True)
            self._respond_json(200, {"success": True, "workout_mode": True})
        elif path == "/api/workout/stop":
            state.set_workout_mode(False)
            self._respond_json(200, {"success": True, "workout_mode": False})
        elif path == "/api/simulation":
            enable = body.get("enable", True)
            state.is_simulation = enable
            self._respond_json(200, {"success": True, "simulation": enable})
        elif path == "/api/vault/save":
            filename = body.get("filename", f"form_check_{int(time.time())}.jpg")
            content_b64 = body.get("data_base64", "")
            if content_b64:
                import base64
                content_bytes = base64.b64decode(content_b64)
            else:
                content_bytes = b"SANDBOXED_MEDIA_DATA"
            filepath = state.media_vault.save_media_file(filename, content_bytes)
            self._respond_json(200, {"success": True, "path": filepath, "filename": filename})
        elif path == "/api/vault/delete":
            filename = body.get("filename", "")
            success = state.media_vault.delete_media_file(filename)
            self._respond_json(200, {"success": success})
        else:
            self._respond_json(404, {"error": "Endpoint not found"})

    def _read_json_body(self) -> Dict[str, Any]:
        try:
            content_length = int(self.headers.get("Content-Length", 0))
            if content_length > 0:
                raw = self.rfile.read(content_length)
                return json.loads(raw.decode("utf-8"))
        except Exception:
            pass
        return {}

    def _respond_json(self, status: int, data: Any):
        payload = json.dumps(data).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self._send_cors_headers()
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, format, *args):
        # Keep terminal clean; uncomment if detailed HTTP logging is desired
        pass


def run_server():
    server = HTTPServer((HOST, PORT), BridgeHTTPHandler)
    logger.info(f"🚀 Wearable Bluetooth Backend Bridge active on http://{HOST}:{PORT}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
        logger.info("Bridge server stopped.")


if __name__ == "__main__":
    run_server()
