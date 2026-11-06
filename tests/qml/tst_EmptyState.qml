import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components"

Item {
    id: container
    width: units.gu(40)
    height: units.gu(50)

    EmptyState {
        id: emptyState
        anchors.centerIn: parent
        title: "No Active Workout"
        message: "You do not have an active workout right now."
        useAnimation: true
    }

    TestCase {
        name: "EmptyStateTest"
        when: windowShown

        function test_title_and_message() {
            compare(emptyState.title, "No Active Workout");
            compare(emptyState.message, "You do not have an active workout right now.");
            compare(emptyState.useAnimation, true);
        }

        function test_toggle_animation() {
            emptyState.useAnimation = false;
            compare(emptyState.useAnimation, false);

            emptyState.useAnimation = true;
            compare(emptyState.useAnimation, true);
        }
    }
}

