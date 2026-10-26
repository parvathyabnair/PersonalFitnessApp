import QtQuick 2.7
import Lomiri.Components 1.3

Rectangle {
    id: card
    property string title: ""
    property string value: "0"
    property string unit: ""
    property string icon: ""
    property color accentColor: "#FF5252"
    property color cardBgColor: (typeof root !== "undefined" && root.cardBgColor) ? root.cardBgColor : "#FFFFFF"
    property color cardBorderColor: (typeof root !== "undefined" && root.cardBorderColor) ? root.cardBorderColor : "#E9ECEF"
    property color textPrimaryColor: (typeof root !== "undefined" && root.textPrimaryColor) ? root.textPrimaryColor : "#1A1B1E"
    property color textSecondaryColor: (typeof root !== "undefined" && root.textSecondaryColor) ? root.textSecondaryColor : "#6C757D"

    width: parent ? (parent.width - units.gu(1.5)) / 2 : units.gu(16)
    height: units.gu(10)
    radius: units.dp(12)
    color: cardBgColor
    border.color: cardBorderColor
    border.width: units.dp(1)

    Column {
        anchors.fill: parent
        anchors.margins: units.gu(1.2)
        spacing: units.gu(0.4)

        Row {
            width: parent.width
            spacing: units.gu(0.6)

            Label {
                text: card.icon
                font.pixelSize: units.gu(1.6)
                visible: card.icon !== ""
            }

            Label {
                text: card.title
                font.pixelSize: units.gu(1.1)
                color: card.textSecondaryColor
                elide: Text.ElideRight
                width: parent.width - (card.icon !== "" ? units.gu(2.4) : 0)
            }
        }

        Row {
            spacing: units.gu(0.4)
            anchors.bottom: parent.bottom

            Label {
                text: card.value
                font.pixelSize: units.gu(2.4)
                font.bold: true
                color: card.accentColor
            }

            Label {
                text: card.unit
                font.pixelSize: units.gu(1.1)
                color: card.textSecondaryColor
                anchors.baseline: parent.children[0].baseline
                visible: card.unit !== ""
            }
        }
    }
}
