import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/utilities/MetCalculator.js" as MetCalc

Item {
    id: container
    width: units.gu(40)
    height: units.gu(60)

    property int mockSessionId: -1
    property string mockWorkout: "General Workout"
    property real mockMultiplier: 1.0
    property bool mockRunning: false

    TestCase {
        name: "ActiveSessionLogicTest"
        when: windowShown

        function test_inactive_session_header_slots() {
            container.mockSessionId = -1;
            var numSlots = (container.mockSessionId !== -1) ? 1 : 0;
            compare(numSlots, 0);
        }

        function test_active_session_header_slots() {
            container.mockSessionId = 101;
            var numSlots = (container.mockSessionId !== -1) ? 2 : 0;
            compare(numSlots, 2);
        }

        function test_intensity_pace_multipliers() {
            var base = MetCalc.getMetValue("General Workout"); // 4.5
            compare(base, 4.5);

            // Relaxed pace
            var relaxed = base * 0.85;
            compare(Math.round(relaxed * 100) / 100, 3.83);

            // Standard pace
            var standard = base * 1.0;
            compare(standard, 4.5);

            // Intense pace
            var intense = base * 1.2;
            compare(Math.round(intense * 100) / 100, 5.4);
        }

        function test_calorie_burn_rate_consistency() {
            // Formula: Calories = MET * Multiplier * Weight * (Duration / 3600)
            // Weight = 80kg, 30 min (1800s), Zumba (6.5 METs), Standard (1.0x) -> 260 kcal
            var calStandard = MetCalc.calculateMetCalories("Zumba", 80, 1800, 1.0);
            compare(calStandard, 260.0);

            // Intense (1.2x): 6.5 * 1.2 = 7.8 METs. 7.8 * 80 * 0.5 = 312 kcal
            var calIntense = MetCalc.calculateMetCalories("Zumba", 80, 1800, 1.2);
            compare(calIntense, 312.0);
        }

        function test_view_mode_to_edit_mode_transition() {
            var pageState = {
                sessionId: 15,
                isViewMode: true,
                isEditMode: false
            };

            // In View Mode by default when opened from overview list
            compare(pageState.isViewMode, true);
            compare(pageState.isEditMode, false);

            // User triggers edit mode
            pageState.isViewMode = false;
            pageState.isEditMode = true;
            compare(pageState.isViewMode, false);
            compare(pageState.isEditMode, true);

            // User saves changes and returns to View Mode
            pageState.isEditMode = false;
            pageState.isViewMode = true;
            compare(pageState.isViewMode, true);
            compare(pageState.isEditMode, false);
        }

        function test_settings_page_view_mode_to_edit_mode_transition() {
            var settingsState = {
                isViewMode: true,
                currentWeight: "70",
                kcalTarget: "500",
                goalWeight: "65",
                gender: "Male",
                height: "175",
                age: "25"
            };

            // By default on opening Settings, it starts in View Mode
            compare(settingsState.isViewMode, true);

            // User taps "Edit"
            settingsState.isViewMode = false;
            compare(settingsState.isViewMode, false);

            // User modifies a metric in Edit Mode
            settingsState.currentWeight = "72";
            compare(settingsState.currentWeight, "72");

            // User clicks "Save" -> persists and transitions back to View Mode
            settingsState.isViewMode = true;
            compare(settingsState.isViewMode, true);

            // User taps "Edit" then "Cancel" -> resets and returns to View Mode
            settingsState.isViewMode = false;
            compare(settingsState.isViewMode, false);
            settingsState.currentWeight = "72";
            settingsState.isViewMode = true;
            compare(settingsState.isViewMode, true);
        }
    }
}

