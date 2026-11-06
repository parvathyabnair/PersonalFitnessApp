import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components"

Item {
    id: container
    width: units.gu(40)
    height: units.gu(40)

    WalkingPersonAnimation {
        id: anim
        anchors.centerIn: parent
        running: true
        isJogging: false
    }

    TestCase {
        name: "WalkingPersonAnimationTest"
        when: windowShown

        function test_defaults() {
            compare(anim.running, true);
            compare(anim.isJogging, false);
            compare(anim.duration, 1080);
            compare(anim.visible, true);
        }

        function test_jogging_cadence_toggle() {
            anim.isJogging = true;
            compare(anim.isJogging, true);
            compare(anim.duration, 720);

            anim.isJogging = false;
            compare(anim.isJogging, false);
            compare(anim.duration, 1080);
        }

        function test_pause_resume() {
            anim.running = false;
            compare(anim.running, false);

            anim.running = true;
            compare(anim.running, true);
        }
    }
}
