import QtQuick 2.7
import Lomiri.Components 1.3

Rectangle {
    id: pill
    property string text: ""
    property color pillColor: "#38BDF8"
    property color textColor: "white"
    property real textSize: units.gu(1.1)

    height: units.gu(2.8)
    width: pillLabel.width + units.gu(2)
    radius: height / 2
    color: pillColor

    Label {
        id: pillLabel
        anchors.centerIn: parent
        text: pill.text
        font.pixelSize: pill.textSize
        font.bold: true
        color: pill.textColor
    }
}
