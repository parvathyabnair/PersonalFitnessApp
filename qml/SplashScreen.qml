import QtQuick 2.4
import Lomiri.Components 1.3

Rectangle {
    id: root
    anchors.fill: parent
    color: "#2D2D2D"

    property string appName: "Test App"
    property string appVersion: "1.0.0"
    property int minimumTime: 5000 // 5 seconds
    property bool ready: true // Set to true for timer-only mode, or control externally
    property bool autoDestroy: false // Set to true if splash should self-destruct
    
    signal finished()

    property bool _done: false

    // Hide splash when both conditions are true (with _done protection)
    states: [
        State {
            name: "done"
            when: root.ready && !minTimer.running && !root._done
        }
    ]

    transitions: [
        Transition {
            from: ""
            to: "done"
            reversible: false

            OpacityAnimator {
                target: contentWrapper
                from: 1.0
                to: 0.0
                duration: 450
            }

            ScriptAction {
                script: {
                    if (!root._done) {
                        root._done = true
                        root.finished()
                        if (root.autoDestroy) {
                            Qt.callLater(function() {
                                root.destroy()
                            })
                        }
                    }
                }
            }
        }
    ]

    Timer {
        id: minTimer
        interval: minimumTime
        running: true
        repeat: false
    }

    // Content wrapper (fade only this, not the root) - prevents glitches in pageLayout/Loader
    Item {
        id: contentWrapper
        anchors.fill: parent
        opacity: 1.0

        Column {
            anchors.centerIn: parent
            spacing: units.gu(3)
            width: parent.width * 0.8

            SplashLogo {
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                text: root.appName
                font.pixelSize: units.gu(3)
                font.bold: true
                color: "white"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                text: "v" + root.appVersion
                font.pixelSize: units.gu(1.5)
                color: "#AAAAAA"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Item {
                id: progressContainer
                width: parent.width
                height: units.gu(1)

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: "#444444"
                }

                Rectangle {
                    id: progressBar
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    width: 0
                    radius: height / 2
                    color: '#f78787'
                }
            }

            Label {
                text: "Loading..."
                font.pixelSize: units.gu(1.5)
                color: Qt.rgba(1, 1, 1)
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    // Progress bar animation
    PropertyAnimation {
        id: progressAnim
        target: progressBar
        property: "width"
        from: 0
        to: progressContainer.width
        duration: minimumTime
        easing.type: Easing.OutQuad
        running: true

        onRunningChanged: {
            if (running) {
                to = progressContainer.width
            }
        }
    }

    // Resize correction: handle window resize after animation
    Connections {
        target: progressContainer
        function onWidthChanged() {
            if (!progressAnim.running && !root._done) {
                progressBar.width = progressContainer.width
            }
        }
    }

    // Safety: prevent multiple state evaluations from triggering multiple finishes
    onReadyChanged: {
        if (ready && !minTimer.running && !root._done) {
            // State will handle transition
        }
    }
}
