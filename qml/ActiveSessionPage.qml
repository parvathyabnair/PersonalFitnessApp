import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtQuick.Layouts 1.3
import "database.js" as DB
import "components"

Page {
    id: activePage
    anchors.fill: parent

    // REQUIRED PROPERTIES
    property var pageLayout
    property int sessionId: -1
    property string workout: "Workout"

    // TIMER PROPERTIES (BIND TO GLOBAL)
    property int secondsElapsed: root.activeSessionSeconds
    property bool isRunning: root.activeSessionRunning

    // NEXT EXERCISE CONFIRM FLAG
    property bool confirmNext: false
    property bool isSaved: false
    property real caloriesBurned: 0.0

    // Rest Timer Properties
    property int restDuration: 60
    property int restTimeLeft: 0
    property bool restTimerRunning: false

    Timer {
        id: restTimer
        interval: 1000
        running: restTimerRunning
        repeat: true
        onTriggered: {
            if (restTimeLeft > 1) {
                restTimeLeft--
            } else {
                restTimeLeft = 0
                restTimerRunning = false
            }
        }
    }

    // FORMAT TIME
    property string timeString: {
        var hours = Math.floor(secondsElapsed / 3600)
        var mins = Math.floor((secondsElapsed % 3600) / 60)
        var secs = secondsElapsed % 60
        return ("0" + hours).slice(-2) + ":" + ("0" + mins).slice(-2) + ":" + ("0" + secs).slice(-2)
    }

    function handleSaveSession() {
        if (root.activeSessionId === -1) return;
        var timeTaken = root.activeSessionSeconds
        var weight = 70 // default
        var settings = DB.getSettings()
        if (settings && settings.weight) {
            weight = parseFloat(settings.weight)
        }

        // Calories burned = MET (4) * weight (kg) * duration (hours)
        var durationHours = timeTaken / 3600
        caloriesBurned = 4 * weight * durationHours

        DB.updateSessionTime(root.activeSessionId, timeTaken)
        DB.updateSessionCalories(root.activeSessionId, caloriesBurned)

        isSaved = true   
        root.activeSessionRunning = false

        PopupUtils.open(savedDialog)
    }

    header: PageHeader {
        title: i18n.tr("Active Session")

        StyleHints {
            foregroundColor: "white"
            backgroundColor: root.primaryColor
            dividerColor: LomiriColors.slate
        }

        trailingActionBar.numberOfSlots: 2
        trailingActionBar.actions: [
            Action {
                iconName: "save"
                text: i18n.tr("Save Session")
                enabled: root.activeSessionId !== -1
                onTriggered: handleSaveSession()
            }
        ]
    }

    // NO ACTIVE SESSIONS VIEW
    Item {
        anchors.fill: parent
        anchors.topMargin: header.height
        visible: root.activeSessionId === -1

        Column {
            anchors.centerIn: parent
            spacing: units.gu(2.5)
            width: parent.width - units.gu(4)

            EmptyState {
                anchors.horizontalCenter: parent.horizontalCenter
                title: i18n.tr("No Active Workout")
                message: i18n.tr("You don't have a session running right now. Choose a workout or quick start to track your time and burned calories.")
            }

            Button {
                text: i18n.tr("Quick Start Workout")
                color: root.primaryColor
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(units.gu(26), parent.width * 0.8)
                height: units.gu(5)

                onClicked: {
                    var today = new Date().toISOString()
                    var id = DB.insertSession("General Workout", "1", JSON.stringify([""]), JSON.stringify([""]), today)
                    if (id !== -1) {
                        root.activeSessionId = id
                        root.activeSessionWorkout = "General Workout"
                        root.activeSessionSeconds = 0
                        root.activeSessionRunning = true
                        activePage.isSaved = false
                    }
                }
            }

            Button {
                text: i18n.tr("Configure Custom Workout")
                color: root.cardBorderColor
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(units.gu(26), parent.width * 0.8)
                height: units.gu(5)

                onClicked: {
                    pageLayout.addPageToNextColumn(activePage, Qt.resolvedUrl("SessionCreatePage.qml"), {pageLayout: pageLayout})
                }
            }
        }
    }

    // MAIN ACTIVE WORKOUT UI (Scrollable)
    Flickable {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        contentWidth: width
        contentHeight: activeContentColumn.height + units.gu(6)
        clip: true
        visible: root.activeSessionId !== -1
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.DragOverBounds

        Column {
            id: activeContentColumn
            width: parent.width - units.gu(3)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: units.gu(2)
            topPadding: units.gu(2)
            bottomPadding: units.gu(3)

            // WORKOUT HEADER CARD
            Rectangle {
                width: parent.width
                height: units.gu(9)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)

                Column {
                    anchors.centerIn: parent
                    spacing: units.gu(0.5)
                    width: parent.width - units.gu(2)

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: units.gu(0.8)

                        Rectangle {
                            width: units.gu(1)
                            height: units.gu(1)
                            radius: width / 2
                            color: root.activeSessionRunning ? "#10B981" : "#F59E0B"
                            anchors.verticalCenter: parent.verticalCenter

                            SequentialAnimation on opacity {
                                running: root.activeSessionRunning
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 0.2; duration: 600 }
                                NumberAnimation { from: 0.2; to: 1.0; duration: 600 }
                            }
                        }

                        Label {
                            text: root.activeSessionRunning ? i18n.tr("SESSION IN PROGRESS") : i18n.tr("SESSION PAUSED")
                            font.bold: true
                            font.pixelSize: units.gu(1.2)
                            color: root.activeSessionRunning ? "#10B981" : "#F59E0B"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Label {
                        text: root.activeSessionWorkout
                        font.bold: true
                        font.pixelSize: units.gu(2.4)
                        color: root.textPrimaryColor
                        anchors.horizontalCenter: parent.horizontalCenter
                        elide: Text.ElideRight
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // DIGITAL STOPWATCH CARD
            Rectangle {
                width: parent.width
                height: units.gu(18)
                radius: units.dp(16)
                color: root.isDarkMode ? "#18191B" : "#1E2024"
                border.color: root.isDarkMode ? "#2E3035" : "#2D3139"
                border.width: units.dp(1)

                Column {
                    anchors.centerIn: parent
                    spacing: units.gu(1.5)
                    width: parent.width - units.gu(2)

                    Label {
                        text: {
                            if (root.activeSessionTargetSeconds > 0) {
                                var targetHrs = Math.floor(root.activeSessionTargetSeconds / 3600)
                                var targetMins = Math.floor((root.activeSessionTargetSeconds % 3600) / 60)
                                var targetSecs = root.activeSessionTargetSeconds % 60
                                var targetStr = ("0" + targetHrs).slice(-2) + ":" + ("0" + targetMins).slice(-2) + ":" + ("0" + targetSecs).slice(-2)
                                return timeString + " / " + targetStr
                            }
                            return timeString
                        }
                        font.pixelSize: units.gu(4.8)
                        font.bold: true
                        font.family: "Monospace"
                        color: "#FFFFFF"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    // Target reached notification
                    Rectangle {
                        visible: root.activeSessionTargetSeconds > 0 && root.activeSessionSeconds >= root.activeSessionTargetSeconds
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: units.gu(3)
                        width: targetReachedLabel.width + units.gu(3)
                        radius: height / 2
                        color: "#059669"

                        Label {
                            id: targetReachedLabel
                            anchors.centerIn: parent
                            text: i18n.tr("🎉 Workout Target Reached!")
                            font.bold: true
                            font.pixelSize: units.gu(1.3)
                            color: "white"
                        }
                    }

                    // Active Workout Calories
                    Rectangle {
                        height: units.gu(3.2)
                        width: calLabel.width + units.gu(3)
                        radius: height / 2
                        color: root.isDarkMode ? "#25262B" : "#2E3035"
                        anchors.horizontalCenter: parent.horizontalCenter

                        Label {
                            id: calLabel
                            anchors.centerIn: parent
                            text: {
                                var weight = 70;
                                var s = DB.getSettings();
                                if (s && s.weight) weight = parseFloat(s.weight);
                                var cal = 4 * weight * (root.activeSessionSeconds / 3600);
                                return "🔥 " + cal.toFixed(1) + " kcal";
                            }
                            font.pixelSize: units.gu(1.3)
                            font.bold: true
                            color: "#FF8A8A"
                        }
                    }
                }
            }

            // PRIMARY CONTROL BUTTONS ROW
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: units.gu(1.5)
                width: parent.width

                Button {
                    text: root.activeSessionRunning ? i18n.tr("Pause") : i18n.tr("Resume")
                    color: root.activeSessionRunning ? "#F59E0B" : root.primaryColor
                    width: (parent.width - units.gu(3)) / 3
                    height: units.gu(4.8)
                    onClicked: root.activeSessionRunning = !root.activeSessionRunning
                }

                Button {
                    text: i18n.tr("Finish & Save")
                    color: root.primaryColor
                    width: (parent.width - units.gu(3)) / 3
                    height: units.gu(4.8)
                    onClicked: handleSaveSession()
                }

                Button {
                    text: i18n.tr("Next Exercise")
                    color: root.cardBorderColor
                    width: (parent.width - units.gu(3)) / 3
                    height: units.gu(4.8)
                    onClicked: handleNextExercise()
                }
            }

            // FORM CHECK & PRIVATE MEDIA ATTACHMENT ROW
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width

                Button {
                    text: i18n.tr("📷 Form Check / Photo")
                    color: root.accentBlue
                    width: parent.width
                    height: units.gu(4.5)
                    onClicked: {
                        var layout = (typeof pageLayout !== "undefined" && pageLayout) ? pageLayout : (typeof root !== "undefined" ? root.pageLayout : null)
                        var src = (layout && layout.primaryPage) ? layout.primaryPage : activePage
                        if (layout) {
                            layout.addPageToNextColumn(src, Qt.resolvedUrl("MediaVaultPage.qml"), {
                                pageLayout: layout,
                                filterSessionId: (activePage.sessionId > 0) ? activePage.sessionId : root.activeSessionId
                            })
                        }
                    }
                }
            }

            // REST TIMER CARD
            Rectangle {
                width: parent.width
                height: units.gu(20)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)
                radius: units.dp(12)

                Column {
                    anchors.fill: parent
                    anchors.margins: units.gu(1.5)
                    spacing: units.gu(1.2)

                    RowLayout {
                        width: parent.width

                        Label {
                            text: i18n.tr("⏱️ Rest Interval Timer")
                            font.bold: true
                            font.pixelSize: units.gu(1.7)
                            color: root.textPrimaryColor
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            text: restTimerRunning ? 
                                  i18n.tr("Resting: ") + restTimeLeft + "s" : 
                                  (restTimeLeft === 0 ? i18n.tr("Ready for next set! 💪") : i18n.tr("Paused: ") + restTimeLeft + "s")
                            font.pixelSize: units.gu(1.4)
                            font.bold: true
                            color: restTimerRunning ? root.primaryColor : (restTimeLeft === 0 ? "#10B981" : "#F59E0B")
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
                                width: (activeContentColumn.width - units.gu(6)) / 4
                                height: units.gu(3.8)
                                color: restDuration === modelData ? root.primaryColor : root.cardBorderColor
                                onClicked: {
                                    restDuration = modelData
                                    restTimeLeft = modelData
                                    restTimerRunning = true
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
                            color: root.cardBorderColor
                            onClicked: {
                                if (restDuration > 10) {
                                    restDuration -= 10
                                    if (!restTimerRunning) restTimeLeft = restDuration
                                }
                            }
                        }

                        Button {
                            text: restTimerRunning ? i18n.tr("Pause Rest") : (restTimeLeft === 0 ? i18n.tr("Start Rest") : i18n.tr("Resume Rest"))
                            color: restTimerRunning ? "#F59E0B" : root.primaryColor
                            width: units.gu(14)
                            height: units.gu(4.2)
                            onClicked: {
                                if (restTimeLeft === 0) {
                                    restTimeLeft = restDuration
                                }
                                restTimerRunning = !restTimerRunning
                            }
                        }

                        Button {
                            text: i18n.tr("Reset")
                            color: root.cardBorderColor
                            width: units.gu(6.5)
                            height: units.gu(4.2)
                            onClicked: {
                                restTimerRunning = false
                                restTimeLeft = restDuration
                            }
                        }

                        Button {
                            text: "+ 10s"
                            width: units.gu(6.5)
                            height: units.gu(4.2)
                            color: root.cardBorderColor
                            onClicked: {
                                restDuration += 10
                                if (!restTimerRunning) restTimeLeft = restDuration
                            }
                        }
                    }
                }
            }
        }
    }

    // NEXT EXERCISE FUNCTION
    function handleNextExercise() {
        if (!isSaved) {
            PopupUtils.open(confirmDialog)   
            return
        }

        // CLEAR GLOBAL SESSION STATE AS WE ARE STARTING A NEW ONE
        root.activeSessionId = -1
        root.activeSessionRunning = false
        root.activeSessionSeconds = 0

        // ALLOW NAVIGATION AFTER SAVE
        pageLayout.addPageToNextColumn(activePage, Qt.resolvedUrl("SessionCreatePage.qml"), {pageLayout: pageLayout})
    }

    // CONFIRM DIALOG
    Component {
        id: confirmDialog

        Dialog {
            id: dialog
            title: i18n.tr("Save Workout First")

            Column {
                spacing: units.gu(2)

                Label {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: root.textPrimaryColor
                    text: i18n.tr("Would you like to finish and save this session before starting the next exercise?")
                }

                Row {
                    spacing: units.gu(1.5)
                    anchors.horizontalCenter: parent.horizontalCenter

                    Button {
                        text: i18n.tr("Cancel")
                        color: root.cardBorderColor
                        onClicked: PopupUtils.close(dialog)
                    }

                    Button {
                        text: i18n.tr("Save & Proceed")
                        color: root.primaryColor
                        onClicked: {
                            PopupUtils.close(dialog)
                            handleSaveSession()
                            root.activeSessionId = -1
                            root.activeSessionRunning = false
                            root.activeSessionSeconds = 0
                            pageLayout.addPageToNextColumn(activePage, Qt.resolvedUrl("SessionCreatePage.qml"), {pageLayout: pageLayout})
                        }
                    }
                }
            }
        }
    }

    // SAVED SUCCESS DIALOG
    Component {
        id: savedDialog

        Dialog {
            id: dialogBox
            title: i18n.tr("Session Saved! 🎉")

            Column {
                spacing: units.gu(2)

                Label {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: root.textPrimaryColor
                    text: i18n.tr("Workout session saved successfully! Total duration: " + timeString + ". Estimated calories burned: " + caloriesBurned.toFixed(1) + " kcal.")
                }

                Button {
                    text: i18n.tr("Great!")
                    color: root.primaryColor
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: units.gu(16)

                    onClicked: {
                        PopupUtils.close(dialogBox)
                    }
                }
            }
        }
    }
}