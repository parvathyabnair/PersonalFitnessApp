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

    // FORMAT TIME (Clean, standard MM:SS or HH:MM:SS)
    property string timeString: {
        var hours = Math.floor(secondsElapsed / 3600)
        var mins = Math.floor((secondsElapsed % 3600) / 60)
        var secs = secondsElapsed % 60
        if (hours > 0 || (root.activeSessionTargetSeconds >= 3600)) {
            return ("0" + hours).slice(-2) + ":" + ("0" + mins).slice(-2) + ":" + ("0" + secs).slice(-2)
        } else {
            return ("0" + mins).slice(-2) + ":" + ("0" + secs).slice(-2)
        }
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
                                var targetStr = targetHrs > 0 ?
                                    (("0" + targetHrs).slice(-2) + ":" + ("0" + targetMins).slice(-2) + ":" + ("0" + targetSecs).slice(-2)) :
                                    (("0" + targetMins).slice(-2) + ":" + ("0" + targetSecs).slice(-2))
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
                                var cal = DB.calculateMetCalories(root.activeSessionWorkout, weight, root.activeSessionSeconds, activePage.intensityMultiplier);
                                return "🔥 " + cal.toFixed(1) + " kcal";
                            }
                            font.pixelSize: units.gu(1.4)
                            font.bold: true
                            color: "#FF6B6B"
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

            // REST TIMER CARD
            Rectangle {
                width: parent.width
                height: restCol.height + units.gu(3)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)
                radius: units.dp(12)

                Column {
                    id: restCol
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
                            color: root.textPrimaryColor
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            text: restTimerRunning ? 
                                  (activePage.workoutPausedForRest ? i18n.tr("Resting: ") + restTimeLeft + "s" : i18n.tr("Resting: ") + restTimeLeft + "s") : 
                                  (restTimeLeft === 0 ? i18n.tr("Ready for next set! 💪") : i18n.tr("Paused: ") + restTimeLeft + "s")
                            font.pixelSize: units.gu(1.4)
                            font.bold: true
                            color: restTimerRunning ? root.primaryColor : (restTimeLeft === 0 ? "#10B981" : "#F59E0B")
                        }
                    }

                    // Auto-pause notification banner
                    Rectangle {
                        visible: activePage.workoutPausedForRest
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
                                width: (activeContentColumn.width - units.gu(6)) / 4
                                height: units.gu(3.8)
                                color: (restTimerRunning && restDuration === modelData) ? root.primaryColor : root.cardBorderColor
                                onClicked: {
                                    startRest(modelData)
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
                                adjustRest(-10)
                            }
                        }

                        Button {
                            text: restTimerRunning ? i18n.tr("Pause Rest") : (restTimeLeft === 0 ? i18n.tr("Start Rest") : i18n.tr("Resume Rest"))
                            color: restTimerRunning ? "#F59E0B" : root.primaryColor
                            width: units.gu(14)
                            height: units.gu(4.2)
                            onClicked: {
                                toggleRestPause()
                            }
                        }

                        Button {
                            text: i18n.tr("Reset")
                            color: root.cardBorderColor
                            width: units.gu(6.5)
                            height: units.gu(4.2)
                            onClicked: {
                                resetRest()
                            }
                        }

                        Button {
                            text: "+ 10s"
                            width: units.gu(6.5)
                            height: units.gu(4.2)
                            color: root.cardBorderColor
                            onClicked: {
                                adjustRest(10)
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
        workoutPausedForRest = false
        restTimerRunning = false

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
                    text: i18n.tr("Workout session saved successfully!\n\n⏱️ Duration: " + timeString + "\n🔥 Calories Burned: " + caloriesBurned.toFixed(1) + " kcal\n⚡ Intensity: " + activePage.effectiveMet.toFixed(1) + " METs (" + activePage.metInfo.category + ")\n📊 Calculated via sports science Compendium MET formula.")
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