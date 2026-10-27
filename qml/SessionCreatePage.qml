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
        if (!categorySelector) return "Workout"
        var cat = categorySelector.selectedIndex
        if (cat === 0 && strengthSelector) return strengthSelector.model[strengthSelector.selectedIndex]
        if (cat === 1 && cardioSelector) return cardioSelector.model[cardioSelector.selectedIndex]
        if (cat === 2) return "HIIT Workout"
        if (cat === 3) return "Zumba"
        if (cat === 4 && customSelector) {
            if (customSelector.selectedIndex === 3 && customTextField) {
                return customTextField.text.trim() !== "" ? customTextField.text.trim() : "Custom Workout"
            }
            return customSelector.model[customSelector.selectedIndex]
        }
        return "Workout"
    }

    readonly property real exerciseMet: DB.getMetValue(chosenWorkoutName)
    readonly property var exerciseMetInfo: DB.getMetIntensityInfo(exerciseMet)

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
        var category = categorySelector.model[categorySelector.selectedIndex]
        if (category === "Strength Training") {
            return strengthSelector.model[strengthSelector.selectedIndex]
        } else if (category === "Cardio") {
            return cardioSelector.model[cardioSelector.selectedIndex]
        } else if (category === "HIIT Workout") {
            return "HIIT Workout"
        } else if (category === "Zumba") {
            return "Zumba"
        } else if (category === "Custom Workout") {
            if (customSelector.selectedIndex === 3) {
                return customTextField.text.trim() !== "" ? customTextField.text.trim() : "Custom Workout"
            } else {
                return customSelector.model[customSelector.selectedIndex]
            }
        }
        return "Workout"
    }

    function getTotalDurationSeconds() {
        if (typeof durationMinField === "undefined" || typeof durationSecField === "undefined") {
            return (duration || 0);
        }
        var m = Math.max(0, parseInt(durationMinField.text) || 0)
        var s = Math.max(0, Math.min(59, parseInt(durationSecField.text) || 0))
        return (m * 60) + s
    }

    function saveSessionData() {
        var workoutVal = getSelectedWorkoutName()
        var dateVal = selectedDate !== "" ? selectedDate : new Date().toISOString()
        var totalSecs = getTotalDurationSeconds()

        if (isTimeBased) {
            if (isEditMode) {
                DB.updateSession(sessionId, workoutVal, "1", JSON.stringify([""]), JSON.stringify([""]), dateVal)
                DB.updateSessionTime(sessionId, totalSecs)
                currentSessionId = sessionId
            } else {
                currentSessionId = DB.insertSession(workoutVal, "1", JSON.stringify([""]), JSON.stringify([""]), dateVal)
                DB.updateSessionTime(currentSessionId, totalSecs)
            }
            currentWorkout = workoutVal
        } else {
            var setsVal = setSelector.model[setSelector.selectedIndex]
            var numSets = parseInt(setsVal)

            var wArray = []
            for (var i = 0; i < numSets; i++) {
                wArray.push((weightFields[i] && weightFields[i].text !== undefined) ? weightFields[i].text : "")
            }
            var weightVal = JSON.stringify(wArray)

            var rArray = []
            for (var i = 0; i < numSets; i++) {
                rArray.push((repsFields[i] && repsFields[i].text !== undefined) ? repsFields[i].text : "")
            }
            var repsVal = JSON.stringify(rArray)

            if (isEditMode) {
                DB.updateSession(sessionId, workoutVal, setsVal, repsVal, weightVal, dateVal)
                DB.updateSessionTime(sessionId, totalSecs)
                currentSessionId = sessionId
            } else {
                currentSessionId = DB.insertSession(workoutVal, setsVal, repsVal, weightVal, dateVal)
                if (totalSecs > 0) {
                    DB.updateSessionTime(currentSessionId, totalSecs)
                }
            }
            currentWorkout = workoutVal   
        }

        // Recalculate and update calories for the updated duration
        var cal = DB.calculateMetCalories(workoutVal, userWeight, totalSecs > 0 ? totalSecs : 2700, 1.0)
        DB.updateSessionCalories(currentSessionId, cal)

        isSaved = true
        selectedDate = dateVal
        DB.ACTIVE_SESSION_ID = currentSessionId
        DB.ACTIVE_WORKOUT = currentWorkout
        return currentSessionId
    }

    function navigateToActiveSession() {
        if (currentSessionId === -1) {
            saveSessionData()
        }

        if (pageLayout) {
            root.activeSessionId = currentSessionId
            root.activeSessionWorkout = currentWorkout
            root.activeSessionSeconds = 0
            root.activeSessionRunning = true
            
            var targetSecs = getTotalDurationSeconds()
            if (isTimeBased && targetSecs > 0) {
                root.activeSessionTargetSeconds = targetSecs
            } else {
                root.activeSessionTargetSeconds = -1
            }

            pageLayout.addPageToNextColumn(
                createSessionPage,
                Qt.resolvedUrl("ActiveSessionPage.qml"),
                {
                    pageLayout: pageLayout,
                    sessionId: currentSessionId,
                    workout: currentWorkout
                }
            )
        }
    }

    header: PageHeader {
        title: isEditMode ? i18n.tr("Edit Session") : i18n.tr("Create Session")

        StyleHints {
            foregroundColor: "white"
            backgroundColor: root.primaryColor
            dividerColor: LomiriColors.slate
        }

        trailingActionBar.numberOfSlots: 1
        trailingActionBar.actions: [
            Action {
                iconName: "save"
                text: i18n.tr("Save")
                onTriggered: {
                    saveSessionData()
                    PopupUtils.open(successDialog)
                }
            }
        ]
    }

    Component.onCompleted: {
        if (isEditMode) {
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
                    durationMinField.text = Math.floor(durSec / 60).toString()
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

    Flickable {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        contentWidth: width
        contentHeight: contentColumn.height + units.gu(6)
        clip: true
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.DragOverBounds

        Column {
            id: contentColumn
            width: parent.width - units.gu(3)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: units.gu(2)
            topPadding: units.gu(2)
            bottomPadding: units.gu(3)

            // SECTION 1: WORKOUT CATEGORY & EXERCISE
            Rectangle {
                width: parent.width
                height: catColumn.height + units.gu(3)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)

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
                    spacing: units.gu(1)

                    RowLayout {
                        width: parent.width

                        Row {
                            spacing: units.gu(0.8)
                            Layout.alignment: Qt.AlignVCenter

                            Label {
                                text: "⚡"
                                font.pixelSize: units.gu(1.6)
                            }

                            Label {
                                text: i18n.tr("Metabolic Forecast (Compendium)")
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
                            color: exerciseMetInfo.color
                            opacity: 0.9

                            Row {
                                id: metBadgeRow
                                anchors.centerIn: parent
                                spacing: units.gu(0.4)
                                Label {
                                    text: exerciseMet.toFixed(1) + " METs"
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
                                    text: exerciseMetInfo.label
                                    font.bold: true
                                    font.pixelSize: units.gu(1.3)
                                    color: exerciseMetInfo.color
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
                                        var cal = DB.calculateMetCalories(chosenWorkoutName, userWeight, durationSecs, 1.0)
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
                visible: !isTimeBased

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
                visible: !isTimeBased

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
                                            text: (isEditMode && weightsArray.length > index) ? weightsArray[index] : ""
                                            onTextChanged: {
                                                if (activeFocus) createSessionPage.isSaved = false
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
                                            text: (isEditMode && repsArray.length > index) ? repsArray[index] : ""
                                            onTextChanged: {
                                                if (activeFocus) createSessionPage.isSaved = false
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

            // SECTION: WORKOUT DURATION & TIME
            Rectangle {
                width: parent.width
                height: durationSectionCol.height + units.gu(3)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)
                visible: isEditMode || isTimeBased

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
                                    var m = Math.max(0, parseInt(durationMinField.text) || 0)
                                    var s = Math.max(0, Math.min(59, parseInt(durationSecField.text) || 0))
                                    var hrs = Math.floor(m / 60)
                                    var remM = m % 60
                                    return ("0" + hrs).slice(-2) + ":" + ("0" + remM).slice(-2) + ":" + ("0" + s).slice(-2)
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
                                    return (parseInt(durationMinField.text) === targetM && (parseInt(durationSecField.text) || 0) === 0) ?
                                           root.primaryColor : root.cardBorderColor
                                }
                                onClicked: {
                                    durationMinField.text = parseInt(modelData).toString()
                                    durationSecField.text = "0"
                                    if (createSessionPage.formReady) createSessionPage.isSaved = false
                                }
                            }
                        }
                    }

                    // Precise Minutes and Seconds Input Fields
                    Row {
                        width: parent.width
                        spacing: units.gu(1.5)

                        Column {
                            width: (parent.width - units.gu(1.5)) / 2
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
                                text: duration > 0 ? Math.floor(duration / 60).toString() : (isTimeBased ? "30" : "0")
                                onTextChanged: {
                                    if (activeFocus && createSessionPage.formReady)
                                        createSessionPage.isSaved = false
                                }
                            }
                        }

                        Column {
                            width: (parent.width - units.gu(1.5)) / 2
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
                                text: duration > 0 ? (duration % 60).toString() : "0"
                                onTextChanged: {
                                    if (activeFocus && createSessionPage.formReady)
                                        createSessionPage.isSaved = false
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
                        onClicked: {
                            PopupUtils.open(datePickerPopover, dateButton)
                        }
                    }
                }
            }

            // SECTION 5: ACTION BUTTONS (SEAMLESS ONE-TAP START & SAVE)
            Row {
                width: parent.width
                spacing: units.gu(1.5)

                Button {
                    text: i18n.tr("Start Workout Now")
                    color: root.primaryColor
                    width: (parent.width - units.gu(1.5)) * 0.6
                    height: units.gu(5)

                    onClicked: {
                        saveSessionData()
                        navigateToActiveSession()
                    }
                }

                Button {
                    text: isEditMode ? i18n.tr("Save Changes") : i18n.tr("Save to Log")
                    color: root.cardBorderColor
                    width: (parent.width - units.gu(1.5)) * 0.4
                    height: units.gu(5)

                    onClicked: {
                        saveSessionData()
                        PopupUtils.open(successDialog)
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
            title: i18n.tr("Success! 🎉")

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
                            pageLayout.addPageToNextColumn(pageLayout.primaryPage, Qt.resolvedUrl("AddSessionPage.qml"), {pageLayout: pageLayout})
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
