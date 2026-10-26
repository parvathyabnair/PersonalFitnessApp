import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3

Rectangle {
    id: restTimerRoot

    property int restTimeLeft: 0
    property int restDuration: 60
    property bool restTimerRunning: false
    property bool workoutPausedForRest: false

    property color primaryColor: (typeof root !== "undefined" && root.primaryColor) ? root.primaryColor : "#FF5252"
    property color cardBgColor: (typeof root !== "undefined" && root.cardBgColor) ? root.cardBgColor : "#FFFFFF"
    property color cardBorderColor: (typeof root !== "undefined" && root.cardBorderColor) ? root.cardBorderColor : "#E9ECEF"
    property color textPrimaryColor: (typeof root !== "undefined" && root.textPrimaryColor) ? root.textPrimaryColor : "#1A1B1E"
    property color textSecondaryColor: (typeof root !== "undefined" && root.textSecondaryColor) ? root.textSecondaryColor : "#6C757D"

    signal startRestRequested(int duration)
    signal toggleRestRequested()
    signal resetRestRequested()
    signal adjustRestRequested(int delta)

    width: parent ? parent.width : units.gu(35)
    height: restContentCol.height + units.gu(3)
    color: cardBgColor
    border.color: cardBorderColor
    border.width: units.dp(1)
    radius: units.dp(12)

    Column {
        id: restContentCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: units.gu(1.5)
        spacing: units.gu(1.2)

        RowLayout {
            width: parent.width

            Label {
                text: i18n.tr("⏱️ Rest Interval Timer")
                font.bold: true
                font.pixelSize: units.gu(1.7)
                color: restTimerRoot.textPrimaryColor
            }

            Item { Layout.fillWidth: true }

            Label {
                text: restTimerRunning ? 
                      (workoutPausedForRest ? i18n.tr("Resting: ") + restTimeLeft + "s" : i18n.tr("Resting: ") + restTimeLeft + "s") : 
                      (restTimeLeft === 0 ? i18n.tr("Ready for next set! 💪") : i18n.tr("Paused: ") + restTimeLeft + "s")
                font.pixelSize: units.gu(1.4)
                font.bold: true
                color: restTimerRunning ? restTimerRoot.primaryColor : (restTimeLeft === 0 ? "#10B981" : "#F59E0B")
            }
        }

        // Auto-pause notification banner
        Rectangle {
            visible: restTimerRoot.workoutPausedForRest
            width: parent.width
            height: units.gu(3.2)
            radius: units.dp(6)
            color: Qt.rgba(2/255, 132/255, 199/255, 0.15)
            border.color: "#0284C7"
            border.width: units.dp(1)

            Row {
                anchors.centerIn: parent
                spacing: units.gu(0.6)

                Label {
                    text: "⏸️"
                    font.pixelSize: units.gu(1.1)
                }

                Label {
                    text: i18n.tr("Workout timer auto-paused • Automatically resumes when rest ends")
                    font.pixelSize: units.gu(1.1)
                    font.bold: true
                    color: "#0284C7"
                }
            }
        }

        // PRESET DURATION CHIPS
        Row {
            spacing: units.gu(1)
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: [30, 60, 90, 120]
                Button {
                    text: modelData + "s"
                    width: (restTimerRoot.width - units.gu(6)) / 4
                    height: units.gu(3.8)
                    color: (restTimerRunning && restDuration === modelData) ? restTimerRoot.primaryColor : restTimerRoot.cardBorderColor
                    onClicked: {
                        restTimerRoot.startRestRequested(modelData)
                    }
                }
            }
        }

        // REST TIMER CONTROLS
        Row {
            spacing: units.gu(1.2)
            anchors.horizontalCenter: parent.horizontalCenter

            Button {
                text: "- 10s"
                width: units.gu(6.5)
                height: units.gu(4.2)
                color: restTimerRoot.cardBorderColor
                onClicked: {
                    restTimerRoot.adjustRestRequested(-10)
                }
            }

            Button {
                text: restTimerRunning ? i18n.tr("Pause Rest") : (restTimeLeft === 0 ? i18n.tr("Start Rest") : i18n.tr("Resume Rest"))
                color: restTimerRunning ? "#F59E0B" : restTimerRoot.primaryColor
                width: units.gu(14)
                height: units.gu(4.2)
                onClicked: {
                    restTimerRoot.toggleRestRequested()
                }
            }

            Button {
                text: i18n.tr("Reset")
                color: restTimerRoot.cardBorderColor
                width: units.gu(6.5)
                height: units.gu(4.2)
                onClicked: {
                    restTimerRoot.resetRestRequested()
                }
            }

            Button {
                text: "+ 10s"
                width: units.gu(6.5)
                height: units.gu(4.2)
                color: restTimerRoot.cardBorderColor
                onClicked: {
                    restTimerRoot.adjustRestRequested(10)
                }
            }
        }
    }
}
