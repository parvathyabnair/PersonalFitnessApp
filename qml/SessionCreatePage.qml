import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Pickers 1.3
import QtQuick.Layouts 1.3
import "database.js" as DB

Page {
    id: createSessionPage
    anchors.fill: parent

    property var pageLayout
 
    property bool isEditMode: false
    property bool isViewMode: false
    property int sessionId: -1
    property bool isSaved: false
    property bool formReady: false

    property string workout: ""
    property string sets: ""
    property string reps: ""
    property string weight: ""
    property string date: ""
    property int duration: 0
    readonly property bool isTimeBased: categorySelector && (categorySelector.selectedIndex === 1 || categorySelector.selectedIndex === 2 || categorySelector.selectedIndex === 3)
 
    property var weightsArray: []
    property var weightFields: []
    property var repsArray: []
    property var repsFields: []
    property string selectedDate: new Date().toISOString()
    property var currentSessionId: -1
    property string currentWorkout: ""
    property real userWeight: 70.0

    readonly property string chosenWorkoutName: {
        if (workout && workout !== "" && (!categorySelector || !formReady || isViewMode)) return workout
        if (!categorySelector) return (workout && workout !== "") ? workout : "Workout"
        var cat = categorySelector.selectedIndex
        if (cat === 0 && strengthSelector) return strengthSelector.model[strengthSelector.selectedIndex]
        if (cat === 1 && cardioSelector) return cardioSelector.model[cardioSelector.selectedIndex]
        if (cat === 2) return "HIIT Workout"
        if (cat === 3) return "Zumba"
        if (cat === 4 && customSelector) {
            if (customSelector.selectedIndex === 3 && customTextField) {
                return customTextField.text.trim() !== "" ? customTextField.text.trim() : (workout && workout !== "" ? workout : "Custom Workout")
            }
            return customSelector.model[customSelector.selectedIndex]
        }
        return (workout && workout !== "") ? workout : "Workout"
    }

    readonly property real exerciseMet: DB.getMetValue(chosenWorkoutName)
    readonly property var exerciseMetInfo: DB.getMetIntensityInfo(exerciseMet)
    property real intensityMultiplier: (typeof root !== "undefined" && root.activeSessionIntensityMultiplier) ? root.activeSessionIntensityMultiplier : 1.0
    property string intensityLevel: (typeof root !== "undefined" && root.activeSessionIntensityLevel) ? root.activeSessionIntensityLevel : "standard"
    readonly property real effectiveMet: exerciseMet * intensityMultiplier

    property var strengthWorkouts: [
        "Dumbbell Bench Press",
        "Push Ups",
        "Squats",
        "Deadlift",
        "Shoulder Press",
        "Lunges",
        "Triceps",
        "Lateral Raises",
        "Leg Extensions and Curls",
        "Calf Raises",
        "Bicep Curls",
        "Planks",
        "Pull-ups and Chin-ups",
        "Bench Press"
    ]

    property var cardioWorkouts: [
        "Running",
        "Cycling",
        "Swimming",
        "Rowing",
        "Elliptical",
        "Stair Climber",
        "Jump Rope",
        "Treadmill Walk"
    ]

    property var customWorkouts: [
        "Push",
        "Pull",
        "Full Body",
        "Manual Entry"
    ]

    function getSelectedWorkoutName() {
        return chosenWorkoutName
    }

    function getTotalDurationSeconds() {
        if (typeof durationMinField === "undefined" || typeof durationSecField === "undefined") {
            return (duration || 0);
        }
        var h = (typeof durationHourField !== "undefined") ? Math.max(0, parseInt(durationHourField.text) || 0) : 0
        var m = Math.max(0, parseInt(durationMinField.text) || 0)
        var s = Math.max(0, Math.min(59, parseInt(durationSecField.text) || 0))
        return (h * 3600) + (m * 60) + s
    }

    function saveSessionData() {
        var workoutVal = getSelectedWorkoutName()
        var dateVal = selectedDate !== "" ? selectedDate : new Date().toISOString()
        var totalSecs = getTotalDurationSeconds()

        // Check if we are updating an existing session to prevent duplicate database rows
        var targetId = -1
        if (isEditMode && sessionId !== -1) {
            targetId = sessionId
        } else if (currentSessionId !== -1) {
            targetId = currentSessionId
        }

        if (targetId !== -1) {
            // ALREADY EXISTS IN DB - UPDATE INSTEAD OF DUPLICATING
            if (isTimeBased) {
                DB.updateSession(targetId, workoutVal, "1", JSON.stringify([""]), JSON.stringify([""]), dateVal)
                DB.updateSessionTime(targetId, totalSecs)
            } else {
                var setsVal = setSelector.model[setSelector.selectedIndex]
                var numSets = parseInt(setsVal)

                var wArray = []
                for (var i = 0; i < numSets; i++) {
                    wArray.push((weightFields[i] && weightFields[i].text !== undefined) ? weightFields[i].text : "")
                }
                var weightVal = JSON.stringify(wArray)
                weightsArray = wArray

                var rArray = []
                for (var i = 0; i < numSets; i++) {
                    rArray.push((repsFields[i] && repsFields[i].text !== undefined) ? repsFields[i].text : "")
                }
                var repsVal = JSON.stringify(rArray)
                repsArray = rArray

                DB.updateSession(targetId, workoutVal, setsVal, repsVal, weightVal, dateVal)
                if (totalSecs > 0) {
                    DB.updateSessionTime(targetId, totalSecs)
                }
            }
            currentSessionId = targetId
            sessionId = targetId
            currentWorkout = workoutVal
            workout = workoutVal
            duration = totalSecs
        } else {
            // BRAND NEW SESSION - INSERT FOR THE FIRST TIME
            if (isTimeBased) {
                currentSessionId = DB.insertSession(workoutVal, "1", JSON.stringify([""]), JSON.stringify([""]), dateVal)
                DB.updateSessionTime(currentSessionId, totalSecs)
            } else {
                var setsVal = setSelector.model[setSelector.selectedIndex]
                var numSets = parseInt(setsVal)

                var wArray = []
                for (var i = 0; i < numSets; i++) {
                    wArray.push((weightFields[i] && weightFields[i].text !== undefined) ? weightFields[i].text : "")
                }
                var weightVal = JSON.stringify(wArray)
                weightsArray = wArray

                var rArray = []
                for (var i = 0; i < numSets; i++) {
                    rArray.push((repsFields[i] && repsFields[i].text !== undefined) ? repsFields[i].text : "")
                }
                var repsVal = JSON.stringify(rArray)
                repsArray = rArray

                currentSessionId = DB.insertSession(workoutVal, setsVal, repsVal, weightVal, dateVal)
                if (totalSecs > 0) {
                    DB.updateSessionTime(currentSessionId, totalSecs)
                }
            }
            sessionId = currentSessionId
            currentWorkout = workoutVal   
            workout = workoutVal
            duration = totalSecs
        }

        // Recalculate and update calories for the updated duration
        var cal = DB.calculateMetCalories(workoutVal, userWeight, totalSecs > 0 ? totalSecs : 2700, intensityMultiplier)
        DB.updateSessionCalories(currentSessionId, cal)

        isSaved = true
        selectedDate = dateVal
        DB.ACTIVE_SESSION_ID = currentSessionId
        DB.ACTIVE_WORKOUT = currentWorkout
        if (typeof root !== "undefined") {
            if (root.activeSessionId === -1 || root.activeSessionId === currentSessionId) {
                root.activeSessionWorkout = currentWorkout
                root.activeSessionIntensityMultiplier = intensityMultiplier
                root.activeSessionIntensityLevel = intensityLevel
            }
        }
        if (typeof mainView !== "undefined" && typeof mainView.sessionDataChanged === "function") {
            mainView.sessionDataChanged()
        } else if (typeof root !== "undefined" && typeof root.sessionDataChanged === "function") {
            root.sessionDataChanged()
        }
        return currentSessionId
    }

    function navigateToActiveSession() {
        if (currentSessionId === -1) {
            saveSessionData()
        }

        if (pageLayout) {
            if (typeof root !== "undefined") {
                root.activeSessionWorkout = currentWorkout
                root.activeSessionIntensityMultiplier = intensityMultiplier
                root.activeSessionIntensityLevel = intensityLevel
            }

            // If the active session is ALREADY running for this session, do not wipe elapsed seconds
            if (root.activeSessionId !== currentSessionId || !root.activeSessionRunning) {
                root.activeSessionId = currentSessionId
                root.activeSessionWorkout = currentWorkout
                root.activeSessionIntensityMultiplier = intensityMultiplier
                root.activeSessionIntensityLevel = intensityLevel
                root.activeSessionSeconds = 0
                root.activeSessionRunning = true
                
                var targetSecs = getTotalDurationSeconds()
                if (isTimeBased && targetSecs > 0) {
                    root.activeSessionTargetSeconds = targetSecs
                } else {
                    root.activeSessionTargetSeconds = -1
                }
            } else {
                root.activeSessionWorkout = currentWorkout
                root.activeSessionIntensityMultiplier = intensityMultiplier
                root.activeSessionIntensityLevel = intensityLevel
            }

            pageLayout.addPageToNextColumn(
                createSessionPage,
                Qt.resolvedUrl("ActiveSessionPage.qml"),
                {
                    pageLayout: pageLayout,
                    sessionId: currentSessionId,
                    workout: currentWorkout,
                    intensityMultiplier: intensityMultiplier,
                    intensityLevel: intensityLevel
                }
            )
        }
    }

    header: PageHeader {
        title: isViewMode ? i18n.tr("Workout Details") : (isEditMode ? i18n.tr("Edit Session") : i18n.tr("Create Session"))

        StyleHints {
            foregroundColor: "white"
            backgroundColor: root.primaryColor
            dividerColor: LomiriColors.slate
        }

        leadingActionBar.actions: [
            Action {
                iconName: "back"
                text: i18n.tr("Back")
                onTriggered: {
                    if (pageLayout && typeof pageLayout.removePages === "function") {
                        pageLayout.removePages(createSessionPage)
                    }
                }
            }
        ]

        trailingActionBar.numberOfSlots: (isEditMode && sessionId !== -1) ? 2 : 1
        trailingActionBar.actions: isViewMode ? [editHeaderAction] : ((isEditMode && sessionId !== -1) ? [saveHeaderAction, cancelHeaderAction] : [saveHeaderAction])

        Action {
            id: editHeaderAction
            iconName: "edit"
            text: i18n.tr("Edit")
            visible: isViewMode
            onTriggered: {
                isViewMode = false
                isEditMode = true
            }
        }

        Action {
            id: saveHeaderAction
            iconName: "save"
            text: i18n.tr("Save")
            visible: !isViewMode
            onTriggered: {
                saveSessionData()
                if (isEditMode) {
                    isEditMode = false
                    isViewMode = true
                }
                PopupUtils.open(successDialog)
            }
        }

        Action {
            id: cancelHeaderAction
            iconName: "close"
            text: i18n.tr("Cancel")
            visible: isEditMode && sessionId !== -1
            onTriggered: {
                isEditMode = false
                isViewMode = true
            }
        }
    }

    Component.onCompleted: {
        if (isEditMode || isViewMode || sessionId !== -1) {
            currentSessionId = sessionId
            var strengthIdx = strengthWorkouts.indexOf(workout)
            var cardioIdx = cardioWorkouts.indexOf(workout)
            
            if (strengthIdx !== -1) {
                categorySelector.selectedIndex = 0
                strengthSelector.selectedIndex = strengthIdx
            } else if (cardioIdx !== -1) {
                categorySelector.selectedIndex = 1
                cardioSelector.selectedIndex = cardioIdx
            } else if (workout === "HIIT Workout") {
                categorySelector.selectedIndex = 2
            } else if (workout === "Zumba") {
                categorySelector.selectedIndex = 3
            } else {
                categorySelector.selectedIndex = 4
                var customIdx = customWorkouts.indexOf(workout)
                if (customIdx !== -1 && customIdx !== 3) {
                    customSelector.selectedIndex = customIdx
                } else {
                    customSelector.selectedIndex = 3
                    customTextField.text = workout
                }
            }

            var setsIndex = setSelector.model.indexOf(sets)
            if (setsIndex !== -1) setSelector.selectedIndex = setsIndex

            if (weight && weight !== "") {
                try { weightsArray = JSON.parse(weight); } catch(e) { weightsArray = []; }
            }
            if (reps && reps !== "") {
                try { repsArray = JSON.parse(reps); } catch(e) { repsArray = []; }
            }

            if (duration !== undefined && duration !== null && duration !== "") {
                var durSec = parseInt(duration) || 0
                if (typeof durationMinField !== "undefined") {
                    if (typeof durationHourField !== "undefined") {
                        durationHourField.text = Math.floor(durSec / 3600).toString()
                    }
                    durationMinField.text = Math.floor((durSec % 3600) / 60).toString()
                    durationSecField.text = (durSec % 60).toString()
                }
            }

            if (date) {
                selectedDate = date
            }
        }
        var s = DB.getSettings()
        if (s && s.weight) {
            var pw = parseFloat(s.weight)
            if (pw > 0) userWeight = pw
        }
        formReady = true
    }

    PropertyAnimation {
        id: scrollAnim
        target: sessionFlickable
        property: "contentY"
        duration: 200
        easing.type: Easing.OutQuad
    }

    function ensureVisible(item) {
        if (!item || !sessionFlickable) return
        var pos = item.mapToItem(sessionFlickable.contentItem, 0, 0)
        var itemY = pos.y
        var itemHeight = item.height
        var viewportHeight = sessionFlickable.height
        var margin = units.gu(4)

        var newContentY = sessionFlickable.contentY
        if (itemY - margin < sessionFlickable.contentY) {
            newContentY = Math.max(0, itemY - margin)
        } else if (itemY + itemHeight + margin > sessionFlickable.contentY + viewportHeight) {
            var targetY = itemY + itemHeight + margin - viewportHeight
            var maxY = Math.max(0, sessionFlickable.contentHeight - viewportHeight)
            newContentY = Math.min(maxY, targetY)
        }

        if (Math.abs(newContentY - sessionFlickable.contentY) > 1) {
            scrollAnim.stop()
            scrollAnim.to = newContentY
            scrollAnim.start()
        }
    }

    Connections {
        target: Qt.inputMethod
        onVisibleChanged: {
            if (Qt.inputMethod.visible) {
                ensureVisibleTimer.restart()
            }
        }
        onKeyboardRectangleChanged: {
            if (Qt.inputMethod.visible) {
                ensureVisibleTimer.restart()
            }
        }
    }

    Timer {
        id: ensureVisibleTimer
        interval: 120
        repeat: false
        onTriggered: {
            if (customTextField && customTextField.activeFocus) {
                ensureVisible(customTextField)
                return
            }
            for (var i = 0; i < weightFields.length; i++) {
                if (weightFields[i] && weightFields[i].activeFocus) {
                    ensureVisible(weightFields[i])
                    return
                }
            }
            for (var j = 0; j < repsFields.length; j++) {
                if (repsFields[j] && repsFields[j].activeFocus) {
                    ensureVisible(repsFields[j])
                    return
                }
            }
            if (typeof durationHourField !== "undefined" && durationHourField && durationHourField.activeFocus) {
                ensureVisible(durationHourField)
            } else if (typeof durationMinField !== "undefined" && durationMinField && durationMinField.activeFocus) {
                ensureVisible(durationMinField)
            } else if (typeof durationSecField !== "undefined" && durationSecField && durationSecField.activeFocus) {
                ensureVisible(durationSecField)
            }
        }
    }

    Flickable {
        id: sessionFlickable
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Qt.inputMethod.visible ? (Qt.inputMethod.keyboardRectangle.height > 0 ? Qt.inputMethod.keyboardRectangle.height : units.gu(30)) : 0
        anchors.left: parent.left
        anchors.right: parent.right
        contentWidth: width
        contentHeight: contentColumn.height + (Qt.inputMethod.visible ? units.gu(14) : units.gu(6))
        clip: true
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.DragOverBounds

        onFlickStarted: {
            if (Qt.inputMethod.visible) Qt.inputMethod.hide()
        }

        Behavior on anchors.bottomMargin {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }

        Column {
            id: contentColumn
            width: parent.width - units.gu(3)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: units.gu(2)
            topPadding: units.gu(2)
            bottomPadding: units.gu(3)

            // VIEW MODE: WORKOUT HEADER CARD
            Rectangle {
                width: parent.width
                height: viewCatCol.height + units.gu(3)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)
                visible: isViewMode

                Column {
                    id: viewCatCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: units.gu(1.5)
                    spacing: units.gu(0.8)

                    RowLayout {
                        width: parent.width

                        Rectangle {
                            height: units.gu(2.6)
                            width: catBadgeLabel.width + units.gu(1.6)
                            radius: height / 2
                            color: root.isDarkMode ? Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, 0.2) : Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, 0.12)
                            border.color: root.primaryColor
                            border.width: units.dp(1)

                            Label {
                                id: catBadgeLabel
                                anchors.centerIn: parent
                                text: (categorySelector && categorySelector.model && categorySelector.model.length > categorySelector.selectedIndex) ?
                                      categorySelector.model[categorySelector.selectedIndex] : i18n.tr("Workout")
                                font.bold: true
                                font.pixelSize: units.gu(1.05)
                                color: root.primaryColor
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            text: selectedDate === "" ? 
                                  Qt.formatDate(new Date(), "MMM d, yyyy") : 
                                  Qt.formatDate(new Date(selectedDate), "MMM d, yyyy")
                            font.pixelSize: units.gu(1.1)
                            color: root.textSecondaryColor
                        }
                    }

                    Label {
                        text: chosenWorkoutName
                        font.bold: true
                        font.pixelSize: units.gu(2.0)
                        color: root.textPrimaryColor
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }
            }

            // SECTION 1: WORKOUT CATEGORY & EXERCISE (EDIT / CREATE MODE)
            Rectangle {
                width: parent.width
                height: catColumn.height + units.gu(3)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)
                visible: !isViewMode

                Column {
                    id: catColumn
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: units.gu(1.5)
                    spacing: units.gu(1.2)

                    Label {
                        text: i18n.tr("Workout Category")
                        font.bold: true
                        font.pixelSize: units.gu(1.6)
                        color: root.textPrimaryColor
                    }

                    OptionSelector {
                        id: categorySelector
                        model: [
                            "Strength Training",
                            "Cardio",
                            "HIIT Workout",
                            "Zumba",
                            "Custom Workout"
                        ]
                        onSelectedIndexChanged: {
                            if (Qt.inputMethod.visible) Qt.inputMethod.hide()
                            if (createSessionPage.formReady)
                                createSessionPage.isSaved = false
                        }
                    }

                    // Strength Training Sub-selector
                    Label {
                        text: i18n.tr("Exercise")
                        visible: categorySelector.selectedIndex === 0
                        font.bold: true
                        font.pixelSize: units.gu(1.5)
                        color: root.textPrimaryColor
                    }
                    OptionSelector {
                        id: strengthSelector
                        model: strengthWorkouts
                        visible: categorySelector.selectedIndex === 0
                        onSelectedIndexChanged: {
                            if (Qt.inputMethod.visible) Qt.inputMethod.hide()
                            if (createSessionPage.formReady)
                                createSessionPage.isSaved = false
                        }
                    }

                    // Cardio Sub-selector
                    Label {
                        text: i18n.tr("Cardio Activity")
                        visible: categorySelector.selectedIndex === 1
                        font.bold: true
                        font.pixelSize: units.gu(1.5)
                        color: root.textPrimaryColor
                    }
                    OptionSelector {
                        id: cardioSelector
                        model: cardioWorkouts
                        visible: categorySelector.selectedIndex === 1
                        onSelectedIndexChanged: {
                            if (Qt.inputMethod.visible) Qt.inputMethod.hide()
                            if (createSessionPage.formReady)
                                createSessionPage.isSaved = false
                        }
                    }

                    // Custom Sub-selector
                    Label {
                        text: i18n.tr("Routine Type")
                        visible: categorySelector.selectedIndex === 4
                        font.bold: true
                        font.pixelSize: units.gu(1.5)
                        color: root.textPrimaryColor
                    }
                    OptionSelector {
                        id: customSelector
                        model: customWorkouts
                        visible: categorySelector.selectedIndex === 4
                        onSelectedIndexChanged: {
                            if (Qt.inputMethod.visible) Qt.inputMethod.hide()
                            if (createSessionPage.formReady)
                                createSessionPage.isSaved = false
                        }
                    }

                    // Custom Workout Name TextField
                    TextField {
                        id: customTextField
                        placeholderText: i18n.tr("Enter workout name...")
                        width: parent.width
                        visible: categorySelector.selectedIndex === 4 && customSelector.selectedIndex === 3
                        onTextChanged: {
                            if (createSessionPage.formReady)
                                createSessionPage.isSaved = false
                        }
                        onAccepted: Qt.inputMethod.hide()
                        onActiveFocusChanged: {
                            if (activeFocus) ensureVisibleTimer.restart()
                        }
                    }
                }
            }

            // SECTION 1.5: MET METABOLIC BURN PREDICTION CARD
            Rectangle {
                width: parent.width
                height: metForecastCol.height + units.gu(2.6)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)

                Column {
                    id: metForecastCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: units.gu(1.4)
                    spacing: units.gu(1.2)

                    RowLayout {
                        width: parent.width

                        Row {
                            spacing: units.gu(0.8)
                            Layout.alignment: Qt.AlignVCenter

                            Label {
                                text: i18n.tr("Metabolic Forecast")
                                font.bold: true
                                font.pixelSize: units.gu(1.4)
                                color: root.textPrimaryColor
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            height: units.gu(2.8)
                            width: metBadgeRow.width + units.gu(1.6)
                            radius: height / 2
                            color: (intensityLevel === "light") ? root.secondaryColor :
                                   (intensityLevel === "high" || intensityLevel === "vigorous") ? "#EF4444" : "#34D399"
                            opacity: 0.9

                            Row {
                                id: metBadgeRow
                                anchors.centerIn: parent
                                spacing: units.gu(0.4)
                                Label {
                                    text: effectiveMet.toFixed(1) + " METs"
                                    font.bold: true
                                    font.pixelSize: units.gu(1.1)
                                    color: "white"
                                }
                            }
                        }
                    }

                    // Burn estimate display
                    Rectangle {
                        width: parent.width
                        height: units.gu(6.5)
                        radius: units.dp(8)
                        color: root.isDarkMode ? "#25262B" : "#F8F9FA"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: units.gu(1)

                            Column {
                                Layout.fillWidth: true
                                spacing: units.gu(0.2)

                                Label {
                                    text: (intensityLevel === "light") ? i18n.tr("Relaxed Pace") :
                                          (intensityLevel === "high" || intensityLevel === "vigorous") ? i18n.tr("Intense Pace") :
                                          i18n.tr("Standard Pace")
                                    font.bold: true
                                    font.pixelSize: units.gu(1.3)
                                    color: (intensityLevel === "light") ? root.secondaryColor :
                                           (intensityLevel === "high" || intensityLevel === "vigorous") ? "#EF4444" : "#34D399"
                                }

                                Label {
                                    text: {
                                        var sec = getTotalDurationSeconds()
                                        if (sec > 0) {
                                            var m = Math.floor(sec / 60)
                                            return (isEditMode ? i18n.tr("Duration: ") : i18n.tr("Target: ")) + m + " mins (" + userWeight + " kg)"
                                        }
                                        return isTimeBased ? i18n.tr("Target: 30 mins (" + userWeight + " kg)") : i18n.tr("Est. 45-min gym workout (" + userWeight + " kg)")
                                    }
                                    font.pixelSize: units.gu(1.0)
                                    color: root.textSecondaryColor
                                }
                            }

                            Column {
                                spacing: units.gu(0.2)

                                Label {
                                    text: {
                                        var durationSecs = getTotalDurationSeconds() > 0 ? getTotalDurationSeconds() : (isTimeBased ? 30 * 60 : 45 * 60)
                                        var cal = DB.calculateMetCalories(chosenWorkoutName, userWeight, durationSecs, intensityMultiplier)
                                        return "~" + Math.round(cal) + " kcal"
                                    }
                                    font.bold: true
                                    font.pixelSize: units.gu(2.0)
                                    color: root.accentOrange
                                    anchors.right: parent.right
                                }

                                Label {
                                    text: i18n.tr("Estimated Burn")
                                    font.pixelSize: units.gu(0.9)
                                    color: root.textSecondaryColor
                                    anchors.right: parent.right
                                }
                            }
                        }
                    }

                    // Burn Rate & Hourly Estimate Row (Aligned exactly with Active Session)
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
                                    var ratePerMin = (effectiveMet * userWeight) / 60.0
                                    return "~" + ratePerMin.toFixed(1) + " kcal / min"
                                }
                                font.bold: true
                                font.pixelSize: units.gu(1.6)
                                color: root.accentOrange
                            }
                        }

                        Column {
                            spacing: units.gu(0.2)
                            Layout.alignment: Qt.AlignRight

                            Label {
                                text: i18n.tr("Hourly Burn")
                                font.pixelSize: units.gu(1.1)
                                color: root.textSecondaryColor
                                anchors.right: parent.right
                            }

                            Label {
                                text: {
                                    var ratePerHour = effectiveMet * userWeight
                                    return "~" + Math.round(ratePerHour) + " kcal / hr"
                                }
                                font.bold: true
                                font.pixelSize: units.gu(1.6)
                                color: root.secondaryColor
                                anchors.right: parent.right
                            }
                        }
                    }

                    // Workout Effort / Intensity Multiplier Selector
                    Column {
                        width: parent.width
                        spacing: units.gu(0.6)

                        Label {
                            text: i18n.tr("Workout Pace / Effort:")
                            font.bold: true
                            font.pixelSize: units.gu(1.2)
                            color: root.textSecondaryColor
                        }

                        Row {
                            width: parent.width
                            spacing: units.gu(0.8)

                            // Relaxed Effort
                            Rectangle {
                                width: (parent.width - units.gu(1.6)) / 3
                                height: units.gu(3.8)
                                radius: units.dp(8)
                                color: intensityLevel === "light" ? root.secondaryColor : (root.isDarkMode ? "#25262B" : "#F1F3F5")
                                border.color: intensityLevel === "light" ? root.secondaryColor : root.cardBorderColor
                                border.width: units.dp(1)

                                Label {
                                    anchors.centerIn: parent
                                    text: i18n.tr("Relaxed")
                                    font.bold: intensityLevel === "light"
                                    font.pixelSize: units.gu(1.1)
                                    color: intensityLevel === "light" ? "white" : root.textPrimaryColor
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: isViewMode ? Qt.ArrowCursor : Qt.PointingHandCursor
                                    enabled: !isViewMode
                                    onClicked: {
                                        intensityMultiplier = 0.85
                                        intensityLevel = "light"
                                        if (typeof root !== "undefined") {
                                            root.activeSessionIntensityMultiplier = 0.85
                                            root.activeSessionIntensityLevel = "light"
                                        }
                                    }
                                }
                            }

                            // Standard Effort
                            Rectangle {
                                width: (parent.width - units.gu(1.6)) / 3
                                height: units.gu(3.8)
                                radius: units.dp(8)
                                color: (intensityLevel === "moderate" || intensityLevel === "standard") ? root.primaryColor : (root.isDarkMode ? "#25262B" : "#F1F3F5")
                                border.color: (intensityLevel === "moderate" || intensityLevel === "standard") ? root.primaryColor : root.cardBorderColor
                                border.width: units.dp(1)

                                Label {
                                    anchors.centerIn: parent
                                    text: i18n.tr("Standard")
                                    font.bold: (intensityLevel === "moderate" || intensityLevel === "standard")
                                    font.pixelSize: units.gu(1.1)
                                    color: (intensityLevel === "moderate" || intensityLevel === "standard") ? "white" : root.textPrimaryColor
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: isViewMode ? Qt.ArrowCursor : Qt.PointingHandCursor
                                    enabled: !isViewMode
                                    onClicked: {
                                        intensityMultiplier = 1.0
                                        intensityLevel = "standard"
                                        if (typeof root !== "undefined") {
                                            root.activeSessionIntensityMultiplier = 1.0
                                            root.activeSessionIntensityLevel = "standard"
                                        }
                                    }
                                }
                            }

                            // Intense Effort
                            Rectangle {
                                width: (parent.width - units.gu(1.6)) / 3
                                height: units.gu(3.8)
                                radius: units.dp(8)
                                color: (intensityLevel === "vigorous" || intensityLevel === "high") ? "#EF4444" : (root.isDarkMode ? "#25262B" : "#F1F3F5")
                                border.color: (intensityLevel === "vigorous" || intensityLevel === "high") ? "#EF4444" : root.cardBorderColor
                                border.width: units.dp(1)

                                Label {
                                    anchors.centerIn: parent
                                    text: i18n.tr("Intense")
                                    font.bold: (intensityLevel === "vigorous" || intensityLevel === "high")
                                    font.pixelSize: units.gu(1.1)
                                    color: (intensityLevel === "vigorous" || intensityLevel === "high") ? "white" : root.textPrimaryColor
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: isViewMode ? Qt.ArrowCursor : Qt.PointingHandCursor
                                    enabled: !isViewMode
                                    onClicked: {
                                        intensityMultiplier = 1.2
                                        intensityLevel = "high"
                                        if (typeof root !== "undefined") {
                                            root.activeSessionIntensityMultiplier = 1.2
                                            root.activeSessionIntensityLevel = "high"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // VIEW MODE: SETS & REPETITIONS BREAKDOWN
            Rectangle {
                width: parent.width
                height: viewSetsCol.height + units.gu(3)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)
                visible: isViewMode && !isTimeBased

                Column {
                    id: viewSetsCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: units.gu(1.5)
                    spacing: units.gu(1.2)

                    RowLayout {
                        width: parent.width

                        Label {
                            text: i18n.tr("Sets Breakdown")
                            font.bold: true
                            font.pixelSize: units.gu(1.6)
                            color: root.textPrimaryColor
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            text: (weightsArray.length > 0 ? weightsArray.length : (parseInt(sets) || 1)) + " " + i18n.tr("Sets")
                            font.bold: true
                            font.pixelSize: units.gu(1.2)
                            color: root.primaryColor
                        }
                    }

                    Repeater {
                        model: Math.max(1, Math.max(weightsArray.length, parseInt(sets) || 1))

                        Rectangle {
                            width: parent.width
                            height: units.gu(4.8)
                            radius: units.dp(8)
                            color: root.isDarkMode ? "#2C2D32" : "#F8F9FA"
                            border.color: root.cardBorderColor
                            border.width: units.dp(1)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: units.gu(1.2)
                                anchors.rightMargin: units.gu(1.2)

                                Rectangle {
                                    width: units.gu(2.8)
                                    height: units.gu(2.8)
                                    radius: width / 2
                                    color: Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, 0.15)

                                    Label {
                                        anchors.centerIn: parent
                                        text: (index + 1).toString()
                                        font.bold: true
                                        font.pixelSize: units.gu(1.1)
                                        color: root.primaryColor
                                    }
                                }

                                Label {
                                    text: i18n.tr("Set ") + (index + 1)
                                    font.bold: true
                                    font.pixelSize: units.gu(1.2)
                                    color: root.textPrimaryColor
                                }

                                Item { Layout.fillWidth: true }

                                Row {
                                    spacing: units.gu(1.2)
                                    Layout.alignment: Qt.AlignVCenter

                                    Label {
                                        text: (weightsArray.length > index && weightsArray[index] !== "" ? weightsArray[index] : "--") + " kg"
                                        font.bold: true
                                        font.pixelSize: units.gu(1.2)
                                        color: root.textPrimaryColor
                                    }

                                    Label {
                                        text: "•"
                                        font.pixelSize: units.gu(1.2)
                                        color: root.textSecondaryColor
                                    }

                                    Label {
                                        text: (repsArray.length > index && repsArray[index] !== "" ? repsArray[index] : "--") + " reps"
                                        font.bold: true
                                        font.pixelSize: units.gu(1.2)
                                        color: root.textPrimaryColor
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // SECTION 2: WORKOUT PARAMETERS (SETS)
            Rectangle {
                width: parent.width
                height: paramColumn.height + units.gu(3)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)
                visible: !isViewMode && !isTimeBased

                Column {
                    id: paramColumn
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: units.gu(1.5)
                    spacing: units.gu(1.2)

                    Label {
                        text: i18n.tr("Number of Sets")
                        font.bold: true
                        font.pixelSize: units.gu(1.6)
                        color: root.textPrimaryColor
                    }

                    OptionSelector {
                        id: setSelector
                        model: ["1", "2", "3", "4", "5"]
                        onSelectedIndexChanged: {
                            if (Qt.inputMethod.visible) Qt.inputMethod.hide()
                            weightFields = []
                            repsFields = []
                            if (createSessionPage.formReady)
                                createSessionPage.isSaved = false
                        }
                    }
                }
            }

            // SECTION 3: WEIGHT & REPS PER SET
            Rectangle {
                width: parent.width
                height: setsColumn.height + units.gu(3)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)
                visible: !isViewMode && !isTimeBased

                Column {
                    id: setsColumn
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: units.gu(1.5)
                    spacing: units.gu(1.5)

                    Label {
                        text: i18n.tr("Sets Breakdown")
                        font.bold: true
                        font.pixelSize: units.gu(1.6)
                        color: root.textPrimaryColor
                    }

                    Repeater {
                        model: parseInt(setSelector.model[setSelector.selectedIndex])

                        Rectangle {
                            width: parent.width
                            height: units.gu(8.5)
                            radius: units.dp(8)
                            color: root.isDarkMode ? "#2C2D32" : "#F8F9FA"
                            border.color: root.cardBorderColor
                            border.width: units.dp(1)

                            Column {
                                anchors.fill: parent
                                anchors.margins: units.gu(1)
                                spacing: units.gu(0.5)

                                Label {
                                    text: i18n.tr("SET ") + (index + 1)
                                    font.bold: true
                                    font.pixelSize: units.gu(1.3)
                                    color: root.primaryColor
                                }

                                Row {
                                    width: parent.width
                                    spacing: units.gu(1.5)

                                    // Weight Input
                                    Row {
                                        width: (parent.width - units.gu(1.5)) / 2
                                        spacing: units.gu(0.5)

                                        TextField {
                                            width: parent.width - units.gu(3.5)
                                            placeholderText: i18n.tr("Weight")
                                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                                            text: (weightsArray.length > index) ? weightsArray[index] : ""
                                            onTextChanged: {
                                                if (activeFocus) createSessionPage.isSaved = false
                                            }
                                            onAccepted: Qt.inputMethod.hide()
                                            onActiveFocusChanged: {
                                                if (activeFocus) ensureVisibleTimer.restart()
                                            }
                                            Component.onCompleted: weightFields[index] = this
                                            Component.onDestruction: weightFields[index] = null
                                        }

                                        Label {
                                            text: "kg"
                                            anchors.verticalCenter: parent.verticalCenter
                                            font.pixelSize: units.gu(1.3)
                                            color: root.textSecondaryColor
                                        }
                                    }

                                    // Reps Input
                                    Row {
                                        width: (parent.width - units.gu(1.5)) / 2
                                        spacing: units.gu(0.5)

                                        TextField {
                                            width: parent.width - units.gu(4.5)
                                            placeholderText: i18n.tr("Reps")
                                            inputMethodHints: Qt.ImhDigitsOnly
                                            text: (repsArray.length > index) ? repsArray[index] : ""
                                            onTextChanged: {
                                                if (activeFocus) createSessionPage.isSaved = false
                                            }
                                            onAccepted: Qt.inputMethod.hide()
                                            onActiveFocusChanged: {
                                                if (activeFocus) ensureVisibleTimer.restart()
                                            }
                                            Component.onCompleted: repsFields[index] = this
                                            Component.onDestruction: repsFields[index] = null
                                        }

                                        Label {
                                            text: "reps"
                                            anchors.verticalCenter: parent.verticalCenter
                                            font.pixelSize: units.gu(1.3)
                                            color: root.textSecondaryColor
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // VIEW MODE: DURATION CARD
            Rectangle {
                width: parent.width
                height: viewDurCol.height + units.gu(3)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)
                visible: isViewMode

                Column {
                    id: viewDurCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: units.gu(1.5)
                    spacing: units.gu(0.8)

                    RowLayout {
                        width: parent.width

                        Label {
                            text: i18n.tr("Logged Duration")
                            font.bold: true
                            font.pixelSize: units.gu(1.6)
                            color: root.textPrimaryColor
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            height: units.gu(2.8)
                            width: viewDurTextLabel.width + units.gu(2)
                            radius: height / 2
                            color: root.isDarkMode ? "#2C2D32" : "#F1F3F5"
                            border.color: root.cardBorderColor
                            border.width: units.dp(1)

                            Label {
                                id: viewDurTextLabel
                                anchors.centerIn: parent
                                text: {
                                    var sec = getTotalDurationSeconds()
                                    var hrs = Math.floor(sec / 3600)
                                    var remM = Math.floor((sec % 3600) / 60)
                                    var remS = sec % 60
                                    return ("0" + hrs).slice(-2) + ":" + ("0" + remM).slice(-2) + ":" + ("0" + remS).slice(-2)
                                }
                                font.bold: true
                                font.family: "Monospace"
                                font.pixelSize: units.gu(1.3)
                                color: root.primaryColor
                            }
                        }
                    }
                }
            }

            // SECTION: WORKOUT DURATION & TIME (EDIT / CREATE MODE)
            Rectangle {
                width: parent.width
                height: durationSectionCol.height + units.gu(3)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)
                visible: !isViewMode && (isEditMode || isTimeBased)

                Column {
                    id: durationSectionCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: units.gu(1.5)
                    spacing: units.gu(1.2)

                    RowLayout {
                        width: parent.width

                        Row {
                            spacing: units.gu(0.6)
                            Layout.fillWidth: true

                            Label {
                                text: isEditMode ? i18n.tr("Workout Duration") : i18n.tr("Target Duration")
                                font.bold: true
                                font.pixelSize: units.gu(1.6)
                                color: root.textPrimaryColor
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Digital formatted time pill preview
                        Rectangle {
                            height: units.gu(2.8)
                            width: durPreviewLabel.width + units.gu(2)
                            radius: height / 2
                            color: root.isDarkMode ? "#2C2D32" : "#F1F3F5"
                            border.color: root.cardBorderColor
                            border.width: units.dp(1)

                            Label {
                                id: durPreviewLabel
                                anchors.centerIn: parent
                                text: {
                                    var h = (typeof durationHourField !== "undefined") ? Math.max(0, parseInt(durationHourField.text) || 0) : 0
                                    var m = (typeof durationMinField !== "undefined") ? Math.max(0, parseInt(durationMinField.text) || 0) : 0
                                    var s = (typeof durationSecField !== "undefined") ? Math.max(0, Math.min(59, parseInt(durationSecField.text) || 0)) : 0
                                    var totalSec = (h * 3600) + (m * 60) + s
                                    var hrs = Math.floor(totalSec / 3600)
                                    var remM = Math.floor((totalSec % 3600) / 60)
                                    var remS = totalSec % 60
                                    return ("0" + hrs).slice(-2) + ":" + ("0" + remM).slice(-2) + ":" + ("0" + remS).slice(-2)
                                }
                                font.bold: true
                                font.family: "Monospace"
                                font.pixelSize: units.gu(1.3)
                                color: root.primaryColor
                            }
                        }
                    }

                    // Quick duration preset buttons
                    Row {
                        width: parent.width
                        spacing: units.gu(0.8)

                        Repeater {
                            model: ["10m", "15m", "20m", "30m", "45m", "60m"]

                            Button {
                                text: modelData
                                width: (parent.width - units.gu(0.8) * 5) / 6
                                height: units.gu(3.4)
                                color: {
                                    var targetM = parseInt(modelData)
                                    var curH = (typeof durationHourField !== "undefined") ? (parseInt(durationHourField.text) || 0) : 0
                                    var curM = (typeof durationMinField !== "undefined") ? (parseInt(durationMinField.text) || 0) : 0
                                    var curS = (typeof durationSecField !== "undefined") ? (parseInt(durationSecField.text) || 0) : 0
                                    var totalM = (curH * 60) + curM
                                    return (totalM === targetM && curS === 0) ?
                                           root.primaryColor : root.cardBorderColor
                                }
                                onClicked: {
                                    var targetM = parseInt(modelData)
                                    if (typeof durationHourField !== "undefined") {
                                        durationHourField.text = Math.floor(targetM / 60).toString()
                                    }
                                    durationMinField.text = (targetM % 60).toString()
                                    durationSecField.text = "0"
                                    if (createSessionPage.formReady) createSessionPage.isSaved = false
                                }
                            }
                        }
                    }

                    // Precise Hours, Minutes and Seconds Input Fields
                    Row {
                        width: parent.width
                        spacing: units.gu(1.2)

                        // Hours Field
                        Column {
                            width: (parent.width - units.gu(2.4)) / 3
                            spacing: units.gu(0.4)

                            Label {
                                text: i18n.tr("Hours")
                                font.bold: true
                                font.pixelSize: units.gu(1.2)
                                color: root.textSecondaryColor
                            }

                            TextField {
                                id: durationHourField
                                width: parent.width
                                placeholderText: "0"
                                inputMethodHints: Qt.ImhDigitsOnly
                                text: duration > 0 ? Math.floor(parseInt(duration) / 3600).toString() : "0"
                                onTextChanged: {
                                    if (activeFocus && createSessionPage.formReady)
                                        createSessionPage.isSaved = false
                                }
                                onAccepted: Qt.inputMethod.hide()
                                onActiveFocusChanged: {
                                    if (activeFocus) ensureVisibleTimer.restart()
                                }
                            }
                        }

                        // Minutes Field
                        Column {
                            width: (parent.width - units.gu(2.4)) / 3
                            spacing: units.gu(0.4)

                            Label {
                                text: i18n.tr("Minutes")
                                font.bold: true
                                font.pixelSize: units.gu(1.2)
                                color: root.textSecondaryColor
                            }

                            TextField {
                                id: durationMinField
                                width: parent.width
                                placeholderText: "0"
                                inputMethodHints: Qt.ImhDigitsOnly
                                text: duration > 0 ? Math.floor((parseInt(duration) % 3600) / 60).toString() : (isTimeBased ? "30" : "0")
                                onTextChanged: {
                                    if (activeFocus && createSessionPage.formReady)
                                        createSessionPage.isSaved = false
                                }
                                onAccepted: Qt.inputMethod.hide()
                                onActiveFocusChanged: {
                                    if (activeFocus) ensureVisibleTimer.restart()
                                }
                            }
                        }

                        // Seconds Field
                        Column {
                            width: (parent.width - units.gu(2.4)) / 3
                            spacing: units.gu(0.4)

                            Label {
                                text: i18n.tr("Seconds")
                                font.bold: true
                                font.pixelSize: units.gu(1.2)
                                color: root.textSecondaryColor
                            }

                            TextField {
                                id: durationSecField
                                width: parent.width
                                placeholderText: "0"
                                inputMethodHints: Qt.ImhDigitsOnly
                                text: duration > 0 ? (parseInt(duration) % 60).toString() : "0"
                                onTextChanged: {
                                    if (activeFocus && createSessionPage.formReady)
                                        createSessionPage.isSaved = false
                                }
                                onAccepted: Qt.inputMethod.hide()
                                onActiveFocusChanged: {
                                    if (activeFocus) ensureVisibleTimer.restart()
                                }
                            }
                        }
                    }
                }
            }

            // SECTION 4: DATE SELECTION
            Rectangle {
                width: parent.width
                height: dateRowLayout.height + units.gu(3)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)

                RowLayout {
                    id: dateRowLayout
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: units.gu(1.5)

                    Column {
                        Layout.fillWidth: true
                        spacing: units.gu(0.3)

                        Label {
                            text: i18n.tr("Workout Date")
                            font.bold: true
                            font.pixelSize: units.gu(1.6)
                            color: root.textPrimaryColor
                        }

                        Label {
                            text: selectedDate === "" ? 
                                  Qt.formatDate(new Date(), "dddd, MMM d, yyyy") : 
                                  Qt.formatDate(new Date(selectedDate), "dddd, MMM d, yyyy")
                            font.pixelSize: units.gu(1.3)
                            color: root.textSecondaryColor
                        }
                    }

                    Button {
                        id: dateButton
                        text: i18n.tr("Change")
                        color: root.cardBorderColor
                        height: units.gu(4)
                        visible: !isViewMode
                        onClicked: {
                            PopupUtils.open(datePickerPopover, dateButton)
                        }
                    }
                }
            }

            // SECTION 5: ACTION BUTTONS (SEAMLESS ONE-TAP START & SAVE / EDIT)
            Row {
                width: parent.width
                spacing: units.gu(1.5)

                Button {
                    text: (root.activeSessionRunning && root.activeSessionId === currentSessionId && currentSessionId !== -1) ?
                          i18n.tr("Resume Workout") :
                          i18n.tr("Start Workout Now")
                    color: (root.activeSessionRunning && root.activeSessionId === currentSessionId && currentSessionId !== -1) ?
                           root.secondaryColor : root.cardBorderColor
                    width: isViewMode ? (parent.width - units.gu(1.5)) * 0.55 : (parent.width - units.gu(1.5)) * 0.6
                    height: units.gu(5)

                    onClicked: {
                        var startAction = function() {
                            if (!isViewMode) {
                                saveSessionData()
                            }
                            navigateToActiveSession()
                        }
                        if (typeof root !== "undefined" && root.activeSessionId !== -1 && root.activeSessionId !== currentSessionId && typeof root.promptWorkoutConflict === "function") {
                            root.promptWorkoutConflict(startAction)
                        } else {
                            startAction()
                        }
                    }
                }

                Button {
                    text: isViewMode ? i18n.tr("Edit Workout") : (isEditMode ? i18n.tr("Save Changes") : i18n.tr("Save to Log"))
                    color: isViewMode ? root.primaryColor : root.cardBorderColor
                    width: isViewMode ? (parent.width - units.gu(1.5)) * 0.45 : (parent.width - units.gu(1.5)) * 0.4
                    height: units.gu(5)

                    onClicked: {
                        if (isViewMode) {
                            isViewMode = false
                            isEditMode = true
                        } else {
                            saveSessionData()
                            if (isEditMode) {
                                isEditMode = false
                                isViewMode = true
                            }
                            PopupUtils.open(successDialog)
                        }
                    }
                }
            }
        }
    }

    // DATE PICKER POPOVER
    Component {
        id: datePickerPopover

        Popover {
            id: pop

            Column {
                width: units.gu(30)
                spacing: units.gu(2)

                DatePicker {
                    id: picker
                }

                Button {
                    text: i18n.tr("Confirm")
                    color: root.primaryColor
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: units.gu(14)

                    onClicked: {
                        selectedDate = picker.date.toISOString()
                        if (createSessionPage.formReady)
                            createSessionPage.isSaved = false
                        PopupUtils.close(pop)
                    }
                }
            }
        }
    }

    // SUCCESS DIALOG
    Component {
        id: successDialog

        Dialog {
            id: succDialog
            title: i18n.tr("Success!")

            Column {
                spacing: units.gu(2)

                Label {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: root.textPrimaryColor
                    text: i18n.tr("Session saved successfully!")
                }

                Row {
                    spacing: units.gu(1.5)
                    anchors.horizontalCenter: parent.horizontalCenter

                    Button {
                        text: i18n.tr("Back to Overview")
                        color: root.cardBorderColor
                        onClicked: {
                            PopupUtils.close(succDialog)
                            if (pageLayout && typeof pageLayout.removePages === "function") {
                                pageLayout.removePages(createSessionPage)
                            }
                        }
                    }

                    Button {
                        text: i18n.tr("OK")
                        color: root.primaryColor
                        onClicked: PopupUtils.close(succDialog)
                    }
                }
            }
        }
    }
}
