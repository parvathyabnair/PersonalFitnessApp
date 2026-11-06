import QtQuick 2.7
import QtTest 1.0
import Lomiri.Components 1.3
import "../../qml/components"

Item {
    id: container
    width: units.gu(40)
    height: units.gu(20)

    MetricPill {
        id: pill
        text: "3.8 METs"
        pillColor: "#38BDF8"
        textColor: "#FFFFFF"
    }

    TestCase {
        name: "MetricPillTest"
        when: windowShown

        function test_properties() {
            compare(pill.text, "3.8 METs");
            compare(pill.pillColor, "#38bdf8");
            compare(pill.textColor, "#ffffff");
        }

        function test_update_text() {
            pill.text = "6.0 METs";
            compare(pill.text, "6.0 METs");
        }
    }
}

