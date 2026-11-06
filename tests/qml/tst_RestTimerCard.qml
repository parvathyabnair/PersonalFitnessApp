import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components"

Item {
    id: container
    width: units.gu(40)
    height: units.gu(50)

    RestTimerCard {
        id: restCard
        anchors.fill: parent
        restTimeLeft: 45
        restDuration: 60
        restTimerRunning: false
        workoutPausedForRest: false
        primaryColor: "#FF5252"
        cardBgColor: "#1E1F24"
        cardBorderColor: "#2C2D32"
        textPrimaryColor: "#FFFFFF"
        textSecondaryColor: "#94A3B8"
    }

    SignalSpy {
        id: spyStart
        target: restCard
        signalName: "startRestRequested"
    }

    SignalSpy {
        id: spyToggle
        target: restCard
        signalName: "toggleRestRequested"
    }

    SignalSpy {
        id: spyReset
        target: restCard
        signalName: "resetRestRequested"
    }

    SignalSpy {
        id: spyAdjust
        target: restCard
        signalName: "adjustRestRequested"
    }

    TestCase {
        name: "RestTimerCardTest"
        when: windowShown

        function test_initial_properties() {
            compare(restCard.restTimeLeft, 45);
            compare(restCard.restDuration, 60);
            compare(restCard.restTimerRunning, false);
            compare(restCard.workoutPausedForRest, false);
        }

        function test_signal_emission_start() {
            spyStart.clear();
            restCard.startRestRequested(90);
            compare(spyStart.count, 1);
            compare(spyStart.signalArguments[0][0], 90);
        }

        function test_signal_emission_toggle() {
            spyToggle.clear();
            restCard.toggleRestRequested();
            compare(spyToggle.count, 1);
        }

        function test_signal_emission_reset() {
            spyReset.clear();
            restCard.resetRestRequested();
            compare(spyReset.count, 1);
        }

        function test_signal_emission_adjust() {
            spyAdjust.clear();
            restCard.adjustRestRequested(10);
            compare(spyAdjust.count, 1);
            compare(spyAdjust.signalArguments[0][0], 10);

            restCard.adjustRestRequested(-10);
            compare(spyAdjust.count, 2);
            compare(spyAdjust.signalArguments[1][0], -10);
        }

        function test_running_state_update() {
            restCard.restTimerRunning = true;
            restCard.workoutPausedForRest = true;
            restCard.restTimeLeft = 30;

            compare(restCard.restTimerRunning, true);
            compare(restCard.workoutPausedForRest, true);
            compare(restCard.restTimeLeft, 30);
        }
    }
}

