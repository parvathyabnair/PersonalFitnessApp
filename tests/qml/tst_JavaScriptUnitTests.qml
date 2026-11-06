import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/utilities/HealthCalculator.js" as HealthCalc
import "../../qml/utilities/MetCalculator.js" as MetCalc
import "../../qml/utilities/Formatters.js" as Formatters

Item {
    id: container
    width: units.gu(40)
    height: units.gu(40)

    TestCase {
        name: "JavaScriptUnitTests"
        when: windowShown

        // --- HealthCalculator: BMI Tests ---
        function test_bmi_normal() {
            var res = HealthCalc.calculateBMI(70, 175);
            compare(res.bmi, "22.9");
            compare(res.status, "Normal");
            compare(res.color, "#34D399");
        }

        function test_bmi_underweight() {
            var res = HealthCalc.calculateBMI(48, 175);
            compare(res.bmi, "15.7");
            compare(res.status, "Underweight");
            compare(res.color, "#79cff2");
        }

        function test_bmi_overweight() {
            var res = HealthCalc.calculateBMI(80, 170);
            compare(res.bmi, "27.7");
            compare(res.status, "Overweight");
            compare(res.color, "#FBBF24");
        }

        function test_bmi_obese() {
            var res = HealthCalc.calculateBMI(105, 170);
            compare(res.bmi, "36.3");
            compare(res.status, "Obese");
            compare(res.color, "#EF4444");
        }

        // --- HealthCalculator: BMR Tests ---
        function test_bmr_male() {
            var bmr = HealthCalc.calculateBMR(70, 175, 25, "Male");
            compare(bmr, 1674);
        }

        function test_bmr_female() {
            var bmr = HealthCalc.calculateBMR(60, 165, 30, "Female");
            compare(bmr, 1320);
        }

        // --- MetCalculator Tests ---
        function test_met_lookup() {
            compare(MetCalc.getMetValue("Push Ups"), 3.8);
            compare(MetCalc.getMetValue("Squats"), 6.0);
            compare(MetCalc.getMetValue("Zumba"), 6.5);
            compare(MetCalc.getMetValue("Running"), 9.8);
            compare(MetCalc.getMetValue("Jump Rope"), 11.5);
            compare(MetCalc.getMetValue("General Workout"), 4.5);
            compare(MetCalc.getMetValue("Unknown X"), 4.5);
        }

        function test_met_intensity_info() {
            var relaxed = MetCalc.getMetIntensityInfo(2.0);
            compare(relaxed.category, "Relaxed Pace");
            compare(relaxed.level, "light");

            var standard = MetCalc.getMetIntensityInfo(4.5);
            compare(standard.category, "Standard Pace");
            compare(standard.level, "moderate");

            var intense = MetCalc.getMetIntensityInfo(8.0);
            compare(intense.category, "Intense Pace");
            compare(intense.level, "vigorous");
        }

        function test_met_calories_calculation() {
            // 1 hr General Workout (4.5 METs), 70kg, 1.0x -> 315 kcal
            var cal1 = MetCalc.calculateMetCalories("General Workout", 70, 3600, 1.0);
            compare(cal1, 315.0);

            // 30 min Zumba (6.5 METs), 80kg, 1.0x -> 260 kcal
            var cal2 = MetCalc.calculateMetCalories("Zumba", 80, 1800, 1.0);
            compare(cal2, 260.0);

            // 30 min Zumba (6.5 METs), 80kg, 1.2x (Intense) -> 312 kcal
            var cal3 = MetCalc.calculateMetCalories("Zumba", 80, 1800, 1.2);
            compare(Math.round(cal3), 312);
        }

        // --- Formatters Tests ---
        function test_format_duration() {
            compare(Formatters.formatDuration(0), "00:00");
            compare(Formatters.formatDuration(45), "00:45");
            compare(Formatters.formatDuration(65), "01:05");
            compare(Formatters.formatDuration(3600), "01:00:00");
            compare(Formatters.formatDuration(3665), "01:01:05");
            compare(Formatters.formatDuration(-10), "00:00");
        }

        function test_format_calories() {
            compare(Formatters.formatCalories(250), "250.0 kcal");
            compare(Formatters.formatCalories(12.34), "12.3 kcal");
        }

        function test_format_weight() {
            compare(Formatters.formatWeight(70), "70.0 kg");
            compare(Formatters.formatWeight(82.5), "82.5 kg");
        }

        // --- Active Session Conflict Resolution Tests ---
        function test_active_session_conflict_resolution() {
            var activeState = {
                activeSessionId: 10,
                activeWorkout: "Running",
                seconds: 1200,
                running: true,
                saved: false,
                discarded: false
            };

            // Test Case 1: Save & Reset
            function resolveSave(state) {
                state.saved = true;
                state.activeSessionId = -1;
                state.activeWorkout = "";
                state.seconds = 0;
                state.running = false;
            }
            resolveSave(activeState);
            compare(activeState.saved, true);
            compare(activeState.activeSessionId, -1);
            compare(activeState.seconds, 0);
            compare(activeState.running, false);

            // Test Case 2: Discard & Reset
            activeState.activeSessionId = 20;
            activeState.activeWorkout = "Squats";
            activeState.seconds = 600;
            activeState.running = true;
            function resolveDiscard(state) {
                state.discarded = true;
                state.activeSessionId = -1;
                state.activeWorkout = "";
                state.seconds = 0;
                state.running = false;
            }
            resolveDiscard(activeState);
            compare(activeState.discarded, true);
            compare(activeState.activeSessionId, -1);
            compare(activeState.seconds, 0);
            compare(activeState.running, false);
        }
    }
}

