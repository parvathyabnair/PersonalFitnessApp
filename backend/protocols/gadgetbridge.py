"""
Gadgetbridge Protocol Base Module
Implements standard open-source Bluetooth Low Energy (BLE) packet formatting,
GATT parsing for Heart Rate (0x180D), Battery (0x180F), and Activity services.
Compatible with Gadgetbridge Android architecture.
"""

import struct
import time
from typing import Dict, Any, Optional, Tuple


class GadgetbridgeProtocol:
    """Standard parser and formatter for Gadgetbridge BLE wearable protocols."""

    # Standard Bluetooth SIG GATT Service & Characteristic UUIDs
    HEART_RATE_SERVICE = "0000180d-0000-1000-8000-00805f9b34fb"
    HEART_RATE_MEASUREMENT = "00002a37-0000-1000-8000-00805f9b34fb"
    
    BATTERY_SERVICE = "0000180f-0000-1000-8000-00805f9b34fb"
    BATTERY_LEVEL = "00002a19-0000-1000-8000-00805f9b34fb"
    
    DEVICE_INFO_SERVICE = "0000180a-0000-1000-8000-00805f9b34fb"
    FIRMWARE_REVISION = "00002a26-0000-1000-8000-00805f9b34fb"
    HARDWARE_REVISION = "00002a27-0000-1000-8000-00805f9b34fb"

    @staticmethod
    def parse_heart_rate(raw_data: bytes) -> Dict[str, Any]:
        """
        Parses standard Bluetooth GATT Heart Rate Measurement (0x2A37).
        Format:
          - Byte 0: Flags
            - bit 0: HR format (0 = uint8, 1 = uint16)
            - bit 1-2: Sensor contact status
            - bit 3: Energy expended status
            - bit 4: RR-Interval present
          - Byte 1..2: Heart Rate Value (BPM)
        """
        if not raw_data or len(raw_data) < 2:
            return {"heart_rate": 0, "energy_expended": None, "sensor_contact": False}

        flags = raw_data[0]
        hr_is_uint16 = bool(flags & 0x01)
        sensor_contact = bool((flags >> 1) & 0x03)
        energy_expended_present = bool(flags & 0x08)
        rr_interval_present = bool(flags & 0x10)

        offset = 1
        if hr_is_uint16:
            if len(raw_data) < offset + 2:
                return {"heart_rate": 0, "energy_expended": None, "sensor_contact": sensor_contact}
            hr_value = struct.unpack_from("<H", raw_data, offset)[0]
            offset += 2
        else:
            hr_value = raw_data[offset]
            offset += 1

        energy_expended = None
        if energy_expended_present and len(raw_data) >= offset + 2:
            energy_expended = struct.unpack_from("<H", raw_data, offset)[0]
            offset += 2

        return {
            "heart_rate": int(hr_value),
            "sensor_contact": sensor_contact,
            "energy_expended": energy_expended,
            "timestamp": time.time()
        }

    @staticmethod
    def parse_battery_level(raw_data: bytes) -> int:
        """Parses standard GATT Battery Level (0x2A19). Single uint8 percentage."""
        if not raw_data:
            return 0
        return min(100, max(0, int(raw_data[0])))

    @staticmethod
    def calculate_hr_zone(heart_rate: int, max_hr: int = 190) -> Dict[str, str]:
        """
        Calculates user heart rate zone based on BPM.
        Standard zones:
          - < 50% max HR: Resting
          - 50-60%: Warm-up
          - 60-70%: Fat Burn
          - 70-80%: Cardio / Aerobic
          - 80-90%: Anaerobic Threshold
          - 90%+: Peak / Maximum
        """
        if heart_rate <= 0:
            return {"name": "No Signal", "color": "#A0A0A5", "description": "Sensor idle"}
        
        pct = (heart_rate / max_hr) * 100
        if pct < 50:
            return {"name": "Rest", "color": "#38BDF8", "description": "Resting heart rate"}
        elif pct < 60:
            return {"name": "Warm-up", "color": "#34D399", "description": "Light activity & recovery"}
        elif pct < 70:
            return {"name": "Fat Burn", "color": "#FBBF24", "description": "Moderate aerobic zone"}
        elif pct < 80:
            return {"name": "Cardio", "color": "#FB923C", "description": "Endurance training"}
        elif pct < 90:
            return {"name": "Anaerobic", "color": "#F87171", "description": "High performance"}
        else:
            return {"name": "Peak", "color": "#EF4444", "description": "Maximum effort"}
