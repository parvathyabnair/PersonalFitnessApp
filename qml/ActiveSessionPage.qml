import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3

Page {
    id: activePage

    // 🔥 Data from previous page
    property string workout: ""
    property string sets: ""
    property var weights: []

    // 🔥 Timer
    property int secondsElapsed: 0
    property bool isRunning: true

    header: PageHeader {
        title: "Active Session"

        StyleHints {
            foregroundColor: "white"
            backgroundColor: "#f78787"
        }
    }

    // ⏱ Timer logic
    Timer {
        id: sessionTimer
        interval: 1000   // 1 second
        running: isRunning
        repeat: true

        onTriggered: {
            secondsElapsed++
        }
    }

    // 📱 UI
    Column {
        anchors.centerIn: parent
        spacing: units.gu(3)

        // Workout name
        Label {
            text: workout
            font.bold: true
            font.pixelSize: units.gu(3)
            horizontalAlignment: Text.AlignHCenter
        }

        // Timer display
        Label {
            text: formatTime(secondsElapsed)
            font.pixelSize: units.gu(5)
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
        }

        // Sets & Weights
        Column {
            spacing: units.gu(1)

            Repeater {
                model: weights.length

                Label {
                    text: "Set " + (index + 1) + ": " + weights[index] + " kg"
                }
            }
        }

        // Buttons
        Row {
            spacing: units.gu(2)
            anchors.horizontalCenter: parent.horizontalCenter

            // ⏸ Pause / Resume
            Button {
                text: isRunning ? "Pause" : "Resume"

                onClicked: {
                    isRunning = !isRunning
                }
            }

            // ⏭ Next Exercise
            Button {
                text: "Next Exercise"

                 onTriggered: {
                    pageLayout.addPageToNextColumn(pageLayout.primaryPage,Qt.resolvedUrl("SessionCreatePage.qml"))
                     console.log("Next exercise clicked")

                    // You can later navigate or reset timer
                    secondsElapsed = 0
                }
            

                // onClicked: {
                //     console.log("Next exercise clicked")

                //     // You can later navigate or reset timer
                //     secondsElapsed = 0
                // }
            }
        }
    }

    // Helper function
    function formatTime(sec) {
        var mins = Math.floor(sec / 60)
        var secs = sec % 60

        return (mins < 10 ? "0" + mins : mins) + ":" +
               (secs < 10 ? "0" + secs : secs)
    }
}