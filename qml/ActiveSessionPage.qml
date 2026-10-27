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

    // MET (Metabolic Equivalent of Task) Calculation Properties
    property real intensityMultiplier: 1.0
    property string intensityLevel: "standard" // "light", "standard", "vigorous"
    property real baseMet: DB.getMetValue(root.activeSessionWorkout || workout || "Workout")
    property real effectiveMet: baseMet * intensityMultiplier
    property var metInfo: DB.getMetIntensityInfo(effectiveMet)
    property bool showMetExplainer: false

    // NEXT EXERCISE CONFIRM FLAG
    property bool confirmNext: false
    property bool isSaved: false
    property real caloriesBurned: 0.0

    // Rest Timer Properties (High-Precision Wall-Clock Countdown using Date.now())
    property int restDuration: 60
    property int restTimeLeft: 0
    property bool restTimerRunning: false
    property double restStartTimestamp: 0
    property double restInitialMs: 0
    property bool workoutPausedForRest: false

    function setSessionTime(newTotalSeconds) {
        var s = Math.max(0, parseInt(newTotalSeconds) || 0)
        if (typeof root.setSessionSeconds === "function") {
            root.setSessionSeconds(s)
        } else {
            root.activeSessionSeconds = s
            root.sessionAccumulatedMs = s * 1000
            if (root.activeSessionRunning) {
                root.lastResumeTimestamp = Date.now()
            } else {
                root.lastResumeTimestamp = 0
            }
        }
    }

    function openEditTimeDialog() {
        // Automatically pause the timer in the background
        root.activeSessionRunning = false
        workoutPausedForRest = false
        PopupUtils.open(editTimeDialogComponent)
    }

    function startRest(seconds) {
        if (root.activeSessionRunning) {
            workoutPausedForRest = true
            root.activeSessionRunning = false
        }
        restDuration = seconds
        restInitialMs = seconds * 1000
        restStartTimestamp = Date.now()
        restTimeLeft = seconds
        restTimerRunning = true
    }

    function toggleRestPause() {
        if (restTimerRunning) {
            var elapsedMs = Date.now() - restStartTimestamp
            restInitialMs = Math.max(0, restInitialMs - elapsedMs)
            restTimeLeft = Math.ceil(restInitialMs / 1000)
            restTimerRunning = false
            restStartTimestamp = 0
        } else {
            if (root.activeSessionRunning) {
                workoutPausedForRest = true
                root.activeSessionRunning = false
            }
            if (restTimeLeft <= 0) {
                restInitialMs = restDuration * 1000
                restTimeLeft = restDuration
            } else {
                restInitialMs = restTimeLeft * 1000
            }
            restStartTimestamp = Date.now()
            restTimerRunning = true
        }
    }

    function resetRest() {
        restTimerRunning = false
        restStartTimestamp = 0
        restInitialMs = 0
        restTimeLeft = restDuration
        if (workoutPausedForRest) {
            workoutPausedForRest = false
            root.activeSessionRunning = true
        }
    }

    function adjustRest(deltaSecs) {
        var newDuration = Math.max(10, restDuration + deltaSecs)
        restDuration = newDuration
        if (restTimerRunning) {
            var elapsedMs = Date.now() - restStartTimestamp
            var currentRemainingMs = Math.max(0, restInitialMs - elapsedMs)
            restInitialMs = Math.max(1000, currentRemainingMs + (deltaSecs * 1000))
            restStartTimestamp = Date.now()
            restTimeLeft = Math.ceil(restInitialMs / 1000)
        } else {
            restTimeLeft = restDuration
        }
    }

    Timer {
        id: restTimer
        interval: 200 // Poll 5x/sec against real Date.now() - completely immune to high refresh rate/vsync issues
        running: restTimerRunning
        repeat: true
        onTriggered: {
            if (restTimerRunning && restStartTimestamp > 0) {
                var elapsedMs = Date.now() - restStartTimestamp
                var remainingMs = Math.max(0, restInitialMs - elapsedMs)
                var secs = Math.ceil(remainingMs / 1000)
                restTimeLeft = secs
                if (remainingMs <= 0) {
                    restTimeLeft = 0
                    restTimerRunning = false
                    restStartTimestamp = 0
                    restInitialMs = 0
                    if (workoutPausedForRest) {
                        workoutPausedForRest = false
                        root.activeSessionRunning = true
                    }
                }
            }
        }
    }

    // FORMAT TIME (Always HH:MM:SS format)
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

        // Standard Compendium MET Formula: Calories Burned = MET Value × Weight (kg) × Duration (hours)
        caloriesBurned = DB.calculateMetCalories(root.activeSessionWorkout, weight, timeTaken, intensityMultiplier)

        DB.updateSessionTime(root.activeSessionId, timeTaken)
        DB.updateSessionCalories(root.activeSessionId, caloriesBurned)

        isSaved = true   
        root.activeSessionRunning = false
        workoutPausedForRest = false
        restTimerRunning = false

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
                        root.activeSessionRunning = false
                        activePage.isSaved = false
                        PopupUtils.open(intensityDialogComponent)
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
                            color: root.activeSessionRunning ? "#10B981" : (activePage.workoutPausedForRest ? "#38BDF8" : "#F59E0B")
                            anchors.verticalCenter: parent.verticalCenter

                            SequentialAnimation on opacity {
                                running: root.activeSessionRunning || activePage.workoutPausedForRest
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 0.2; duration: 600 }
                                NumberAnimation { from: 0.2; to: 1.0; duration: 600 }
                            }
                        }

                        Label {
                            text: root.activeSessionRunning ? 
                                  i18n.tr("SESSION IN PROGRESS") : 
                                  (activePage.workoutPausedForRest ? (i18n.tr("REST INTERVAL • ") + activePage.restTimeLeft + "s") : i18n.tr("SESSION PAUSED"))
                            font.bold: true
                            font.pixelSize: units.gu(1.2)
                            color: root.activeSessionRunning ? "#10B981" : (activePage.workoutPausedForRest ? "#38BDF8" : "#F59E0B")
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: units.gu(0.8)

                        Label {
                            text: root.activeSessionWorkout || i18n.tr("Workout")
                            font.bold: true
                            font.pixelSize: units.gu(2.4)
                            color: root.textPrimaryColor
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        Rectangle {
                            width: units.gu(2.8)
                            height: units.gu(2.8)
                            radius: width / 2
                            color: editNameMouseArea.pressed ? root.primaryColor : (root.isDarkMode ? "#2C2D32" : "#E5E7EB")
                            anchors.verticalCenter: parent.verticalCenter

                            Icon {
                                name: "edit"
                                width: units.gu(1.3)
                                height: units.gu(1.3)
                                anchors.centerIn: parent
                                color: editNameMouseArea.pressed ? "#FFFFFF" : root.textSecondaryColor
                            }

                            MouseArea {
                                id: editNameMouseArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: PopupUtils.open(editWorkoutNameDialogComponent)
                            }
                        }
                    }
                }
            }

            // DIGITAL STOPWATCH CARD
            Rectangle {
                width: parent.width
                height: units.gu(20)
                radius: units.dp(16)
                color: root.isDarkMode ? "#18191B" : "#1E2024"
                border.color: root.isDarkMode ? "#2E3035" : "#2D3139"
                border.width: units.dp(1)

                // Top Header Row inside the card: Recording status on left, Edit Time pill on right
                RowLayout {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: units.gu(1.2)
                    anchors.leftMargin: units.gu(1.5)
                    anchors.rightMargin: units.gu(1.5)

                    Row {
                        spacing: units.gu(0.6)
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            width: units.gu(0.8)
                            height: units.gu(0.8)
                            radius: width / 2
                            color: root.activeSessionRunning ? "#10B981" : "#F59E0B"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Label {
                            text: root.activeSessionRunning ? i18n.tr("RECORDING WORKOUT") : i18n.tr("SESSION PAUSED")
                            font.pixelSize: units.gu(1.0)
                            font.bold: true
                            color: root.textSecondaryColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Elegant Top-Right "Edit Time" Action Pill
                    Rectangle {
                        height: units.gu(2.8)
                        width: editBtnRow.width + units.gu(1.8)
                        radius: height / 2
                        color: editMouseArea.pressed ? root.primaryColor : (root.isDarkMode ? "#26282E" : "#2E3037")
                        border.color: root.isDarkMode ? "#373A42" : "#444752"
                        border.width: units.dp(1)

                        Row {
                            id: editBtnRow
                            anchors.centerIn: parent
                            spacing: units.gu(0.4)

                            Icon {
                                name: "edit"
                                width: units.gu(1.2)
                                height: units.gu(1.2)
                                color: editMouseArea.pressed ? "#FFFFFF" : root.textSecondaryColor
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Label {
                                text: i18n.tr("Edit Time")
                                font.pixelSize: units.gu(1.0)
                                font.bold: true
                                color: editMouseArea.pressed ? "#FFFFFF" : root.textSecondaryColor
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: editMouseArea
                            anchors.fill: parent
                            onClicked: openEditTimeDialog()
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: units.gu(0.8)
                    spacing: units.gu(1.2)
                    width: parent.width - units.gu(2)

                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: timerDisplayLabel.width
                        height: timerDisplayLabel.height

                        Label {
                            id: timerDisplayLabel
                            anchors.centerIn: parent
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
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: openEditTimeDialog()
                        }
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

                    // Auto-paused for rest badge
                    Rectangle {
                        visible: activePage.workoutPausedForRest && !root.activeSessionRunning
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: units.gu(3)
                        width: restAutoPauseLabel.width + units.gu(3)
                        radius: height / 2
                        color: "#0284C7"

                        Label {
                            id: restAutoPauseLabel
                            anchors.centerIn: parent
                            text: i18n.tr("⏸️ Auto-Paused for Rest (Resumes in ") + activePage.restTimeLeft + "s)"
                            font.bold: true
                            font.pixelSize: units.gu(1.2)
                            color: "white"
                        }
                    }

                    // Realtime MET Calorie Burn Rate Pill
                    Rectangle {
                        height: units.gu(3.2)
                        width: calPillRow.width + units.gu(2.4)
                        radius: height / 2
                        color: root.isDarkMode ? "#25262B" : "#2E3035"
                        anchors.horizontalCenter: parent.horizontalCenter

                        Row {
                            id: calPillRow
                            anchors.centerIn: parent
                            spacing: units.gu(0.5)

                            Image {
                                source: Qt.resolvedUrl("../assets/fire-svgrepo-com.svg")
                                width: units.gu(1.8)
                                height: units.gu(1.8)
                                sourceSize.width: units.gu(1.8)
                                sourceSize.height: units.gu(1.8)
                                fillMode: Image.PreserveAspectFit
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Label {
                                id: calLabel
                                text: {
                                    var weight = 70;
                                    var s = DB.getSettings();
                                    if (s && s.weight) weight = parseFloat(s.weight);
                                    var cal = DB.calculateMetCalories(root.activeSessionWorkout, weight, root.activeSessionSeconds, activePage.intensityMultiplier);
                                    return cal.toFixed(1) + " kcal";
                                }
                                font.pixelSize: units.gu(1.4)
                                font.bold: true
                                color: "#FF6B6B"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }

            // MET (METABOLIC EQUIVALENT OF TASK) METRICS & INTENSITY CARD
            Rectangle {
                width: parent.width
                height: metColumn.height + units.gu(3)
                radius: units.dp(16)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)

                Column {
                    id: metColumn
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: units.gu(1.5)
                    spacing: units.gu(1.2)

                    RowLayout {
                        width: parent.width

                        Row {
                            spacing: units.gu(0.8)
                            Layout.alignment: Qt.AlignVCenter

                            Label {
                                text: "⚡"
                                font.pixelSize: units.gu(1.8)
                            }

                            Label {
                                text: i18n.tr("Metabolic Rate (MET)")
                                font.bold: true
                                font.pixelSize: units.gu(1.5)
                                color: root.textPrimaryColor
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            height: units.gu(2.6)
                            width: metBadgeText.width + units.gu(1.6)
                            radius: height / 2
                            color: Qt.rgba(0, 0, 0, 0.4)
                            border.color: activePage.metInfo.color
                            border.width: units.dp(1.5)

                            Label {
                                id: metBadgeText
                                anchors.centerIn: parent
                                text: activePage.effectiveMet.toFixed(1) + " METs • " + activePage.metInfo.category
                                font.bold: true
                                font.pixelSize: units.gu(1.1)
                                color: activePage.metInfo.color
                            }
                        }
                    }

                    // Burn Rate & Details Row
                    RowLayout {
                        width: parent.width

                        Column {
                            Layout.fillWidth: true
                            spacing: units.gu(0.2)

                            Label {
                                text: i18n.tr("Caloric Burn Rate")
                                font.pixelSize: units.gu(1.1)
                                color: root.textSecondaryColor
                            }

                            Label {
                                text: {
                                    var weight = 70;
                                    var s = DB.getSettings();
                                    if (s && s.weight) weight = parseFloat(s.weight);
                                    var ratePerMin = (activePage.effectiveMet * weight) / 60.0;
                                    return "~" + ratePerMin.toFixed(1) + " kcal / min";
                                }
                                font.bold: true
                                font.pixelSize: units.gu(1.8)
                                color: root.accentOrange
                            }
                        }

                        Column {
                            spacing: units.gu(0.2)
                            Layout.alignment: Qt.AlignRight

                            Label {
                                text: i18n.tr("Compendium Standard")
                                font.pixelSize: units.gu(1.1)
                                color: root.textSecondaryColor
                                anchors.right: parent.right
                            }

                            Label {
                                text: activePage.baseMet.toFixed(1) + " MET Baseline"
                                font.bold: true
                                font.pixelSize: units.gu(1.4)
                                color: root.accentBlue
                                anchors.right: parent.right
                            }
                        }
                    }

                    // Workout Effort / Intensity Multiplier Selector
                    Column {
                        width: parent.width
                        spacing: units.gu(0.6)

                        Label {
                            text: i18n.tr("Session Intensity Multiplier:")
                            font.bold: true
                            font.pixelSize: units.gu(1.2)
                            color: root.textSecondaryColor
                        }

                        Row {
                            width: parent.width
                            spacing: units.gu(0.8)

                            // Light Effort (0.85x)
                            Rectangle {
                                width: (parent.width - units.gu(1.6)) / 3
                                height: units.gu(3.8)
                                radius: units.dp(8)
                                color: activePage.intensityLevel === "light" ? root.accentBlue : (root.isDarkMode ? "#25262B" : "#F1F3F5")
                                border.color: activePage.intensityLevel === "light" ? root.accentBlue : root.cardBorderColor
                                border.width: units.dp(1)

                                Label {
                                    anchors.centerIn: parent
                                    text: i18n.tr("Light (0.85×)")
                                    font.bold: activePage.intensityLevel === "light"
                                    font.pixelSize: units.gu(1.1)
                                    color: activePage.intensityLevel === "light" ? "white" : root.textPrimaryColor
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        activePage.intensityMultiplier = 0.85
                                        activePage.intensityLevel = "light"
                                    }
                                }
                            }

                            // Standard Effort (1.0x)
                            Rectangle {
                                width: (parent.width - units.gu(1.6)) / 3
                                height: units.gu(3.8)
                                radius: units.dp(8)
                                color: activePage.intensityLevel === "standard" ? root.primaryColor : (root.isDarkMode ? "#25262B" : "#F1F3F5")
                                border.color: activePage.intensityLevel === "standard" ? root.primaryColor : root.cardBorderColor
                                border.width: units.dp(1)

                                Label {
                                    anchors.centerIn: parent
                                    text: i18n.tr("Standard (1.0×)")
                                    font.bold: activePage.intensityLevel === "standard"
                                    font.pixelSize: units.gu(1.1)
                                    color: activePage.intensityLevel === "standard" ? "white" : root.textPrimaryColor
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        activePage.intensityMultiplier = 1.0
                                        activePage.intensityLevel = "standard"
                                    }
                                }
                            }

                            // Vigorous Effort (1.2x)
                            Rectangle {
                                width: (parent.width - units.gu(1.6)) / 3
                                height: units.gu(3.8)
                                radius: units.dp(8)
                                color: activePage.intensityLevel === "vigorous" ? "#EF4444" : (root.isDarkMode ? "#25262B" : "#F1F3F5")
                                border.color: activePage.intensityLevel === "vigorous" ? "#EF4444" : root.cardBorderColor
                                border.width: units.dp(1)

                                Label {
                                    anchors.centerIn: parent
                                    text: i18n.tr("Heavy (1.2×)")
                                    font.bold: activePage.intensityLevel === "vigorous"
                                    font.pixelSize: units.gu(1.1)
                                    color: activePage.intensityLevel === "vigorous" ? "white" : root.textPrimaryColor
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        activePage.intensityMultiplier = 1.2
                                        activePage.intensityLevel = "vigorous"
                                    }
                                }
                            }
                        }
                    }

                    // Sports Science MET Explainer Accordion
                    Rectangle {
                        width: parent.width
                        height: explainerCol.height + units.gu(1.6)
                        radius: units.dp(8)
                        color: root.isDarkMode ? "#1A1D20" : "#F8F9FA"
                        border.color: root.cardBorderColor
                        border.width: units.dp(1)

                        Column {
                            id: explainerCol
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: units.gu(1)
                            spacing: units.gu(0.5)

                            RowLayout {
                                width: parent.width

                                Label {
                                    text: "ℹ️ " + i18n.tr("MET Scientific Metabolic Formula")
                                    font.bold: true
                                    font.pixelSize: units.gu(1.1)
                                    color: root.accentBlue
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: activePage.showMetExplainer ? "▲" : "▼"
                                    font.pixelSize: units.gu(1.1)
                                    color: root.textSecondaryColor
                                }
                            }

                            Column {
                                width: parent.width
                                spacing: units.gu(0.4)
                                visible: activePage.showMetExplainer

                                Label {
                                    text: i18n.tr("Formula: Calories Burned = MET Value × Weight (kg) × Duration (hours)")
                                    font.bold: true
                                    font.pixelSize: units.gu(1.1)
                                    color: root.textPrimaryColor
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                }

                                Label {
                                    text: {
                                        var weight = 70;
                                        var s = DB.getSettings();
                                        if (s && s.weight) weight = parseFloat(s.weight);
                                        var hrs = (root.activeSessionSeconds / 3600.0).toFixed(2);
                                        var cal = DB.calculateMetCalories(root.activeSessionWorkout, weight, root.activeSessionSeconds, activePage.intensityMultiplier);
                                        return i18n.tr("Live Calculation: ") + activePage.effectiveMet.toFixed(1) + " METs × " + weight + " kg × " + hrs + " hrs = " + cal.toFixed(1) + " kcal";
                                    }
                                    font.pixelSize: units.gu(1.1)
                                    color: root.accentGreen
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                }

                                Label {
                                    text: i18n.tr("Compendium of Physical Activities standardized sports medicine reference.")
                                    font.pixelSize: units.gu(1.0)
                                    color: root.textSecondaryColor
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: activePage.showMetExplainer = !activePage.showMetExplainer
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
                    onClicked: {
                        if (!root.activeSessionRunning) {
                            activePage.workoutPausedForRest = false
                            if (activePage.restTimerRunning) {
                                activePage.restTimerRunning = false
                                activePage.restStartTimestamp = 0
                                activePage.restInitialMs = 0
                            }
                            root.activeSessionRunning = true
                        } else {
                            activePage.workoutPausedForRest = false
                            root.activeSessionRunning = false
                        }
                    }
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

            // REST TIMER CARD COMPONENT
            RestTimerCard {
                width: parent.width
                restTimeLeft: activePage.restTimeLeft
                restDuration: activePage.restDuration
                restTimerRunning: activePage.restTimerRunning
                workoutPausedForRest: activePage.workoutPausedForRest
                primaryColor: root.primaryColor
                cardBgColor: root.cardBgColor
                cardBorderColor: root.cardBorderColor
                textPrimaryColor: root.textPrimaryColor
                textSecondaryColor: root.textSecondaryColor

                onStartRestRequested: startRest(duration)
                onToggleRestRequested: toggleRestPause()
                onResetRestRequested: resetRest()
                onAdjustRestRequested: adjustRest(delta)
            }
        }
    }

    // NEXT EXERCISE FUNCTION (Direct workout logging without navigating away)
    function handleNextExercise() {
        // Automatically save current session progress to database if active
        if (root.activeSessionId !== -1 && root.activeSessionSeconds > 0) {
            var weight = 70
            var s = DB.getSettings()
            if (s && s.weight) weight = parseFloat(s.weight)
            var cal = DB.calculateMetCalories(root.activeSessionWorkout, weight, root.activeSessionSeconds, activePage.intensityMultiplier)
            DB.updateSessionTime(root.activeSessionId, root.activeSessionSeconds)
            DB.updateSessionCalories(root.activeSessionId, cal)
            activePage.isSaved = true
        }

        // Pause timer while selecting next exercise
        root.activeSessionRunning = false
        workoutPausedForRest = false
        if (restTimerRunning) {
            resetRest()
        }

        PopupUtils.open(nextExerciseDialogComponent)
    }

    // INTENSITY SELECTION DIALOG (Prompted before starting timer on Quick Start)
    Component {
        id: intensityDialogComponent

        Dialog {
            id: intensityDlg
            title: i18n.tr("Select Workout Intensity")

            Column {
                spacing: units.gu(1.5)
                width: parent.width

                Label {
                    text: i18n.tr("Choose intensity level to start your workout timer and MET calorie tracking:")
                    font.pixelSize: units.gu(1.2)
                    color: root.textSecondaryColor
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                // Light Intensity Button
                Button {
                    width: parent.width
                    height: units.gu(4.8)
                    color: root.accentBlue
                    text: i18n.tr("Light Activity (0.85×) • Warmup & Recovery")
                    onClicked: {
                        activePage.intensityMultiplier = 0.85
                        activePage.intensityLevel = "light"
                        PopupUtils.close(intensityDlg)
                        root.activeSessionRunning = true
                    }
                }

                // Standard Intensity Button (Default)
                Button {
                    width: parent.width
                    height: units.gu(4.8)
                    color: root.primaryColor
                    text: i18n.tr("Moderate Activity (1.0×) • Typical Gym Workout")
                    onClicked: {
                        activePage.intensityMultiplier = 1.0
                        activePage.intensityLevel = "standard"
                        PopupUtils.close(intensityDlg)
                        root.activeSessionRunning = true
                    }
                }

                // Heavy Intensity Button
                Button {
                    width: parent.width
                    height: units.gu(4.8)
                    color: "#EF4444"
                    text: i18n.tr("Vigorous Activity (1.2×) • High Exertion & PRs")
                    onClicked: {
                        activePage.intensityMultiplier = 1.2
                        activePage.intensityLevel = "vigorous"
                        PopupUtils.close(intensityDlg)
                        root.activeSessionRunning = true
                    }
                }

                Button {
                    text: i18n.tr("Cancel")
                    color: root.cardBorderColor
                    width: parent.width
                    height: units.gu(4)
                    onClicked: PopupUtils.close(intensityDlg)
                }
            }
        }
    }

    // EDIT WORKOUT TIME DIALOG (Hour, Minute, Second with auto-pause & resume on play)
    Component {
        id: editTimeDialogComponent

        Dialog {
            id: editTimeDlg
            title: i18n.tr("Edit Workout Time")

            Column {
                spacing: units.gu(1.5)
                width: parent.width

                Label {
                    text: i18n.tr("Adjust or enter current elapsed workout time:")
                    font.pixelSize: units.gu(1.2)
                    color: root.textSecondaryColor
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                // Digital preview in HH:MM:SS
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        var h = Math.max(0, parseInt(hourField.text) || 0)
                        var m = Math.max(0, Math.min(59, parseInt(minField.text) || 0))
                        var s = Math.max(0, Math.min(59, parseInt(secField.text) || 0))
                        return ("0" + h).slice(-2) + ":" + ("0" + m).slice(-2) + ":" + ("0" + s).slice(-2)
                    }
                    font.pixelSize: units.gu(3.5)
                    font.bold: true
                    font.family: "Monospace"
                    color: root.primaryColor
                }

                // Quick Adjustment Buttons
                Row {
                    id: quickAdjRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: units.gu(1)

                    function adjustQuick(deltaSecs) {
                        var cur = (Math.max(0, parseInt(hourField.text) || 0) * 3600) +
                                  (Math.max(0, parseInt(minField.text) || 0) * 60) +
                                  (Math.max(0, parseInt(secField.text) || 0))
                        cur = Math.max(0, cur + deltaSecs)
                        hourField.text = Math.floor(cur / 3600).toString()
                        minField.text = Math.floor((cur % 3600) / 60).toString()
                        secField.text = (cur % 60).toString()
                    }

                    Button {
                        text: "-5m"
                        width: units.gu(6)
                        height: units.gu(3.8)
                        color: root.cardBorderColor
                        onClicked: quickAdjRow.adjustQuick(-300)
                    }
                    Button {
                        text: "-1m"
                        width: units.gu(6)
                        height: units.gu(3.8)
                        color: root.cardBorderColor
                        onClicked: quickAdjRow.adjustQuick(-60)
                    }
                    Button {
                        text: "+1m"
                        width: units.gu(6)
                        height: units.gu(3.8)
                        color: root.cardBorderColor
                        onClicked: quickAdjRow.adjustQuick(60)
                    }
                    Button {
                        text: "+5m"
                        width: units.gu(6)
                        height: units.gu(3.8)
                        color: root.cardBorderColor
                        onClicked: quickAdjRow.adjustQuick(300)
                    }
                }

                // Hours, Minutes, and Seconds Input Fields
                Row {
                    width: parent.width
                    spacing: units.gu(1.0)

                    Column {
                        width: (parent.width - units.gu(2.0)) / 3
                        spacing: units.gu(0.4)

                        Label {
                            text: i18n.tr("Hours")
                            font.bold: true
                            font.pixelSize: units.gu(1.2)
                            color: root.textSecondaryColor
                        }

                        TextField {
                            id: hourField
                            text: Math.floor(root.activeSessionSeconds / 3600).toString()
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            width: parent.width
                        }
                    }

                    Column {
                        width: (parent.width - units.gu(2.0)) / 3
                        spacing: units.gu(0.4)

                        Label {
                            text: i18n.tr("Minutes")
                            font.bold: true
                            font.pixelSize: units.gu(1.2)
                            color: root.textSecondaryColor
                        }

                        TextField {
                            id: minField
                            text: Math.floor((root.activeSessionSeconds % 3600) / 60).toString()
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            width: parent.width
                        }
                    }

                    Column {
                        width: (parent.width - units.gu(2.0)) / 3
                        spacing: units.gu(0.4)

                        Label {
                            text: i18n.tr("Seconds")
                            font.bold: true
                            font.pixelSize: units.gu(1.2)
                            color: root.textSecondaryColor
                        }

                        TextField {
                            id: secField
                            text: (root.activeSessionSeconds % 60).toString()
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            width: parent.width
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: units.gu(1.2)

                    Button {
                        text: i18n.tr("Cancel")
                        color: root.cardBorderColor
                        width: (parent.width - units.gu(1.2)) / 2
                        height: units.gu(4.5)
                        onClicked: PopupUtils.close(editTimeDlg)
                    }

                    Button {
                        text: i18n.tr("Apply Time")
                        color: root.primaryColor
                        width: (parent.width - units.gu(1.2)) / 2
                        height: units.gu(4.5)
                        onClicked: {
                            var h = Math.max(0, parseInt(hourField.text) || 0)
                            var m = Math.max(0, parseInt(minField.text) || 0)
                            var s = Math.max(0, Math.min(59, parseInt(secField.text) || 0))
                            var totalSecs = (h * 3600) + (m * 60) + s
                            activePage.setSessionTime(totalSecs)
                            // Keep paused so user sees edited time and starts only upon clicking resume
                            root.activeSessionRunning = false
                            PopupUtils.close(editTimeDlg)
                        }
                    }
                }
            }
        }
    }

    // NEXT EXERCISE DIALOG (Select Intensity & Log Workout directly without navigating away)
    Component {
        id: nextExerciseDialogComponent

        Dialog {
            id: nextExDlg
            title: i18n.tr("Next Exercise")

            Column {
                spacing: units.gu(1.5)
                width: parent.width

                Label {
                    text: i18n.tr("Previous exercise saved! Select next exercise and intensity to log directly:")
                    font.pixelSize: units.gu(1.2)
                    color: root.textSecondaryColor
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                // Workout Name
                Column {
                    width: parent.width
                    spacing: units.gu(0.4)

                    Label {
                        text: i18n.tr("Exercise / Workout Name")
                        font.bold: true
                        font.pixelSize: units.gu(1.2)
                        color: root.textPrimaryColor
                    }

                    TextField {
                        id: nextWorkoutField
                        text: "General Workout"
                        width: parent.width
                    }
                }

                // Quick exercise suggestions
                Flow {
                    width: parent.width
                    spacing: units.gu(0.6)

                    Repeater {
                        model: ["General Workout", "Push Ups", "Squats", "Planks", "Bicep Curls", "Bench Press"]

                        Rectangle {
                            height: units.gu(3)
                            width: chipLabel.width + units.gu(1.6)
                            radius: height / 2
                            color: nextWorkoutField.text === modelData ? root.primaryColor : root.cardBorderColor

                            Label {
                                id: chipLabel
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: units.gu(1.1)
                                font.bold: nextWorkoutField.text === modelData
                                color: nextWorkoutField.text === modelData ? "#FFFFFF" : root.textPrimaryColor
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: nextWorkoutField.text = modelData
                            }
                        }
                    }
                }

                Label {
                    text: i18n.tr("Select Intensity to Start:")
                    font.bold: true
                    font.pixelSize: units.gu(1.2)
                    color: root.textPrimaryColor
                }

                // Light Intensity Button
                Button {
                    width: parent.width
                    height: units.gu(4.5)
                    color: root.accentBlue
                    text: i18n.tr("Light Effort (0.85×) • Warmup & Mobility")
                    onClicked: startNext(nextWorkoutField.text, 0.85, "light")
                }

                // Standard Intensity Button
                Button {
                    width: parent.width
                    height: units.gu(4.5)
                    color: root.primaryColor
                    text: i18n.tr("Standard Effort (1.0×) • Regular Workout")
                    onClicked: startNext(nextWorkoutField.text, 1.0, "standard")
                }

                // Heavy Intensity Button
                Button {
                    width: parent.width
                    height: units.gu(4.5)
                    color: "#EF4444"
                    text: i18n.tr("Heavy Effort (1.2×) • Vigorous & Intense")
                    onClicked: startNext(nextWorkoutField.text, 1.2, "vigorous")
                }

                Button {
                    text: i18n.tr("Cancel")
                    color: root.cardBorderColor
                    width: parent.width
                    height: units.gu(4)
                    onClicked: {
                        PopupUtils.close(nextExDlg)
                        root.activeSessionRunning = true
                    }
                }
            }

            function startNext(wName, multiplier, level) {
                var finalName = wName.trim() !== "" ? wName.trim() : "General Workout"
                var today = new Date().toISOString()
                var newId = DB.insertSession(finalName, "1", JSON.stringify([""]), JSON.stringify([""]), today)
                if (newId !== -1) {
                    root.activeSessionId = newId
                    root.activeSessionWorkout = finalName
                    activePage.workout = finalName
                    activePage.intensityMultiplier = multiplier
                    activePage.intensityLevel = level
                    activePage.setSessionTime(0)
                    activePage.resetRest()
                    activePage.isSaved = false
                    root.activeSessionRunning = true
                }
                PopupUtils.close(nextExDlg)
            }
        }
    }

    // EDIT WORKOUT NAME DIALOG
    Component {
        id: editWorkoutNameDialogComponent

        Dialog {
            id: editWorkoutNameDlg
            title: i18n.tr("Edit Workout Name")

            Column {
                spacing: units.gu(1.5)
                width: parent.width

                Label {
                    text: i18n.tr("Update the name of your current active workout:")
                    font.pixelSize: units.gu(1.2)
                    color: root.textSecondaryColor
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                TextField {
                    id: editNameField
                    text: root.activeSessionWorkout
                    placeholderText: i18n.tr("Workout name")
                    width: parent.width
                }

                Flow {
                    width: parent.width
                    spacing: units.gu(0.6)

                    Repeater {
                        model: ["Bench Press", "Squats", "Deadlift", "Push Ups", "Pull-ups", "General Workout"]

                        Rectangle {
                            height: units.gu(3)
                            width: sugLabel.width + units.gu(1.6)
                            radius: height / 2
                            color: editNameField.text === modelData ? root.primaryColor : root.cardBorderColor

                            Label {
                                id: sugLabel
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: units.gu(1.1)
                                font.bold: editNameField.text === modelData
                                color: editNameField.text === modelData ? "#FFFFFF" : root.textPrimaryColor
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: editNameField.text = modelData
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: units.gu(1.2)

                    Button {
                        text: i18n.tr("Cancel")
                        color: root.cardBorderColor
                        width: (parent.width - units.gu(1.2)) / 2
                        height: units.gu(4.5)
                        onClicked: PopupUtils.close(editWorkoutNameDlg)
                    }

                    Button {
                        text: i18n.tr("Save")
                        color: root.primaryColor
                        width: (parent.width - units.gu(1.2)) / 2
                        height: units.gu(4.5)
                        onClicked: {
                            var trimmed = editNameField.text.trim()
                            if (trimmed !== "") {
                                root.activeSessionWorkout = trimmed
                                activePage.workout = trimmed
                                if (root.activeSessionId !== -1) {
                                    DB.updateSessionWorkoutName(root.activeSessionId, trimmed)
                                }
                            }
                            PopupUtils.close(editWorkoutNameDlg)
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
                spacing: units.gu(1.5)
                width: parent.width

                Row {
                    spacing: units.gu(0.8)
                    anchors.horizontalCenter: parent.horizontalCenter

                    Image {
                        source: Qt.resolvedUrl("../assets/fire-svgrepo-com.svg")
                        width: units.gu(2.4)
                        height: units.gu(2.4)
                        sourceSize.width: units.gu(2.4)
                        sourceSize.height: units.gu(2.4)
                        fillMode: Image.PreserveAspectFit
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Label {
                        text: caloriesBurned.toFixed(1) + " kcal"
                        font.bold: true
                        font.pixelSize: units.gu(2.0)
                        color: root.accentOrange
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Label {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: root.textPrimaryColor
                    text: i18n.tr("Workout session saved successfully!\n\n⏱️ Duration: " + timeString + "\n⚡ Intensity: " + activePage.effectiveMet.toFixed(1) + " METs (" + activePage.metInfo.category + ")\n📊 Calculated via sports science Compendium MET formula.")
                }

                Button {
                    text: i18n.tr("Great!")
                    color: root.primaryColor
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: units.gu(16)

                    onClicked: {
                        PopupUtils.close(dialogBox)
                        // Reset session state to original page with no workout
                        root.activeSessionId = -1
                        root.activeSessionWorkout = ""
                        root.activeSessionSeconds = 0
                        root.activeSessionTargetSeconds = -1
                        root.activeSessionRunning = false
                        activePage.workout = "Workout"
                        activePage.sessionId = -1
                        activePage.isSaved = false
                        activePage.workoutPausedForRest = false
                        activePage.restTimerRunning = false
                        activePage.resetRest()
                    }
                }
            }
        }
    }
}