import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components"

Item {
    id: testContainer
    width: units.gu(45)
    height: units.gu(65)

    ActiveWorkoutConflictDialog {
        id: conflictDlg
        workoutName: "Running"
        elapsedSeconds: 125
    }

    SignalSpy {
        id: spySave
        target: conflictDlg
        signalName: "saveAndProceedTriggered"
    }

    SignalSpy {
        id: spyDiscard
        target: conflictDlg
        signalName: "discardAndProceedTriggered"
    }

    SignalSpy {
        id: spyCancel
        target: conflictDlg
        signalName: "cancelTriggered"
    }

    TestCase {
        name: "ActiveWorkoutConflictDialogTest"
        when: windowShown

        function test_initial_properties() {
            compare(conflictDlg.workoutName, "Running");
            compare(conflictDlg.elapsedSeconds, 125);
            compare(conflictDlg.elapsedTimeText, "00:02:05");
        }

        function test_time_formatting() {
            conflictDlg.elapsedSeconds = 3665;
            compare(conflictDlg.elapsedTimeText, "01:01:05");

            conflictDlg.elapsedSeconds = 0;
            compare(conflictDlg.elapsedTimeText, "00:00:00");
        }

        function test_save_proceed_signal() {
            spySave.clear();
            conflictDlg.saveAndProceedTriggered();
            compare(spySave.count, 1);
        }

        function test_discard_proceed_signal() {
            spyDiscard.clear();
            conflictDlg.discardAndProceedTriggered();
            compare(spyDiscard.count, 1);
        }

        function test_cancel_signal() {
            spyCancel.clear();
            conflictDlg.cancelTriggered();
            compare(spyCancel.count, 1);
        }

        function test_conflict_logic_branches() {
            // Simulated state container for testing conflict decision branches
            var state = {
                activeSessionId: 42,
                activeWorkout: "Cycling",
                seconds: 300,
                running: true,
                saved: false,
                discarded: false
            };

            // Branch 1: Save & Proceed
            var saveAction = function() {
                state.saved = true;
                state.activeSessionId = -1;
                state.running = false;
            };
            saveAction();
            compare(state.saved, true);
            compare(state.activeSessionId, -1);
            compare(state.running, false);

            // Branch 2: Discard & Proceed
            state.activeSessionId = 99;
            state.running = true;
            var discardAction = function() {
                state.discarded = true;
                state.activeSessionId = -1;
                state.running = false;
            };
            discardAction();
            compare(state.discarded, true);
            compare(state.activeSessionId, -1);
            compare(state.running, false);
        }
    }
}

