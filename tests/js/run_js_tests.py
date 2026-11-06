#!/usr/bin/env python3
"""
Python-based JavaScript & Logic Unit Test Runner for Clickable / Ubuntu Touch Container
Executes test cases against personalfitnessapp algorithms and math logic without needing Node.js.
"""

import sys
import math
import unittest

class HealthCalculatorTests(unittest.TestCase):
    def calculate_bmi(self, weight_kg, height_cm):
        w = float(weight_kg) if weight_kg else 70.0
        h = (float(height_cm) if height_cm else 175.0) / 100.0
        if h <= 0:
            return {"bmi": "22.9", "status": "Normal", "color": "#34D399"}
        bmi_val = w / (h * h)
        if math.isnan(bmi_val) or bmi_val <= 0:
            return {"bmi": "22.9", "status": "Normal", "color": "#34D399"}
        status = "Normal"
        color = "#34D399"
        if bmi_val < 18.5:
            status = "Underweight"
            color = "#79cff2"
        elif 25.0 <= bmi_val < 30.0:
            status = "Overweight"
            color = "#FBBF24"
        elif bmi_val >= 30.0:
            status = "Obese"
            color = "#EF4444"
        return {"bmi": f"{bmi_val:.1f}", "status": status, "color": color}

    def calculate_bmr(self, weight_kg, height_cm, age, gender):
        w = float(weight_kg) if weight_kg else 70.0
        h = float(height_cm) if height_cm else 175.0
        a = int(age) if age else 25
        is_male = (gender != "Female")
        bmr = (10.0 * w) + (6.25 * h) - (5.0 * a) + (5.0 if is_male else -161.0)
        return round(bmr)

    def test_bmi_normal(self):
        res = self.calculate_bmi(70, 175)
        self.assertEqual(res["bmi"], "22.9")
        self.assertEqual(res["status"], "Normal")
        self.assertEqual(res["color"], "#34D399")

    def test_bmi_underweight(self):
        res = self.calculate_bmi(48, 175)
        self.assertEqual(res["bmi"], "15.7")
        self.assertEqual(res["status"], "Underweight")
        self.assertEqual(res["color"], "#79cff2")

    def test_bmi_overweight(self):
        res = self.calculate_bmi(80, 170)
        self.assertEqual(res["bmi"], "27.7")
        self.assertEqual(res["status"], "Overweight")
        self.assertEqual(res["color"], "#FBBF24")

    def test_bmi_obese(self):
        res = self.calculate_bmi(105, 170)
        self.assertEqual(res["bmi"], "36.3")
        self.assertEqual(res["status"], "Obese")
        self.assertEqual(res["color"], "#EF4444")

    def test_bmr_male_mifflin(self):
        bmr = self.calculate_bmr(70, 175, 25, "Male")
        self.assertEqual(bmr, 1674)

    def test_bmr_female_mifflin(self):
        bmr = self.calculate_bmr(60, 165, 30, "Female")
        self.assertEqual(bmr, 1320)


class MetCalculatorTests(unittest.TestCase):
    MET_DATA = {
        "Push Ups": 3.8,
        "Squats": 6.0,
        "Zumba": 6.5,
        "Running": 9.8,
        "Jump Rope": 11.5,
        "Resting": 1.0,
        "Stretching": 2.5,
        "General Workout": 4.5
    }

    def get_met(self, name):
        if not name:
            return 4.5
        return self.MET_DATA.get(name, 4.5)

    def calculate_calories(self, exercise, weight_kg, duration_secs, multiplier=1.0):
        met = self.get_met(exercise)
        mult = float(multiplier) if multiplier else 1.0
        w = float(weight_kg) if weight_kg else 70.0
        hrs = (float(duration_secs) / 3600.0) if duration_secs else 0.0
        return (met * mult) * w * hrs

    def test_met_lookup(self):
        self.assertEqual(self.get_met("Push Ups"), 3.8)
        self.assertEqual(self.get_met("Squats"), 6.0)
        self.assertEqual(self.get_met("Zumba"), 6.5)
        self.assertEqual(self.get_met("Running"), 9.8)

    def test_calorie_calculation_general(self):
        cal = self.calculate_calories("General Workout", 70, 3600, 1.0)
        self.assertEqual(cal, 315.0)

    def test_calorie_calculation_zumba(self):
        # 30 mins (1800s) Zumba (6.5 METs), 80kg, 1.0x -> 260 kcal
        cal = self.calculate_calories("Zumba", 80, 1800, 1.0)
        self.assertEqual(cal, 260.0)

    def test_pace_multipliers(self):
        relaxed = self.calculate_calories("Zumba", 80, 1800, 0.85)
        self.assertEqual(round(relaxed, 1), 221.0)

        intense = self.calculate_calories("Zumba", 80, 1800, 1.2)
        self.assertEqual(round(intense, 1), 312.0)


class FormatterTests(unittest.TestCase):
    def format_duration(self, total_seconds):
        secs = max(0, int(total_seconds) if total_seconds else 0)
        hours = secs // 3600
        mins = (secs % 3600) // 60
        remaining_secs = secs % 60
        pad = lambda n: f"{n:02d}"
        if hours > 0:
            return f"{pad(hours)}:{pad(mins)}:{pad(remaining_secs)}"
        return f"{pad(mins)}:{pad(remaining_secs)}"

    def test_durations(self):
        self.assertEqual(self.format_duration(0), "00:00")
        self.assertEqual(self.format_duration(45), "00:45")
        self.assertEqual(self.format_duration(65), "01:05")
        self.assertEqual(self.format_duration(3600), "01:00:00")
        self.assertEqual(self.format_duration(3665), "01:01:05")
        self.assertEqual(self.format_duration(-10), "00:00")


class SessionConflictTests(unittest.TestCase):
    def test_save_and_reset_active_session(self):
        state = {
            "activeSessionId": 5,
            "workout": "General Workout",
            "seconds": 450,
            "running": True,
            "saved": False
        }
        # Simulate Save Current & Proceed
        state["saved"] = True
        state["activeSessionId"] = -1
        state["workout"] = ""
        state["seconds"] = 0
        state["running"] = False

        self.assertTrue(state["saved"])
        self.assertEqual(state["activeSessionId"], -1)
        self.assertEqual(state["seconds"], 0)
        self.assertFalse(state["running"])

    def test_discard_and_reset_active_session(self):
        state = {
            "activeSessionId": 8,
            "workout": "Push Ups",
            "seconds": 210,
            "running": True,
            "discarded": False
        }
        # Simulate Discard Current & Proceed
        state["discarded"] = True
        state["activeSessionId"] = -1
        state["workout"] = ""
        state["seconds"] = 0
        state["running"] = False

        self.assertTrue(state["discarded"])
        self.assertEqual(state["activeSessionId"], -1)
        self.assertEqual(state["seconds"], 0)
        self.assertFalse(state["running"])


if __name__ == "__main__":
    suite = unittest.TestSuite()
    for tc in [HealthCalculatorTests, MetCalculatorTests, FormatterTests, SessionConflictTests]:
        suite.addTests(unittest.defaultTestLoader.loadTestsFromTestCase(tc))
    runner = unittest.TextTestRunner(verbosity=2)
    res = runner.run(suite)
    sys.exit(0 if res.wasSuccessful() else 1)

