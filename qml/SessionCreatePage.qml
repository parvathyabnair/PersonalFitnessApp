import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Pickers 1.3
import QtQuick.Layouts 1.3
import "database.js" as DB

Page {
    id: createSessionPage

   
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
 
    property var weightsArray: []
    property var weightFields: []
    property var repsArray: []
    property var repsFields: []
    property string selectedDate: ""
    property var currentSessionId: -1
    property string currentWorkout: ""

    function navigateToActiveSession() {
        if (currentSessionId === -1) {
            console.log("Please save first!")
            return
        }

        if (pageLayout) {
            // INITIALIZE GLOBAL SESSION STATE
            root.activeSessionId = currentSessionId
            root.activeSessionWorkout = currentWorkout
            root.activeSessionSeconds = 0
            root.activeSessionRunning = true

            pageLayout.addPageToNextColumn(
                createSessionPage,
                Qt.resolvedUrl("ActiveSessionPage.qml"),
                {
                    pageLayout: pageLayout,
                    sessionId: currentSessionId,
                    workout: currentWorkout
                }
            )
        } else {
            console.log("ERROR: pageLayout undefined")
        }
    }

    header: PageHeader {
        title: isEditMode ? "Edit Session" : "Create New Session"

        StyleHints {
            foregroundColor: "white"
            backgroundColor: "#f78787"
        }

         trailingActionBar.numberOfSlots: 2
            trailingActionBar.actions: [
               Action {
    iconName: "save"
    text: "Save Session"

    onTriggered: {

        var workoutVal = workoutSelector.model[workoutSelector.selectedIndex]
        var setsVal = setSelector.model[setSelector.selectedIndex]

        var numSets = parseInt(setsVal)

        var weightsArray = []
        for (var i = 0; i < numSets; i++) {
            weightsArray.push((weightFields[i] && weightFields[i].text !== undefined) ? weightFields[i].text : "")
        }

        var weightVal = JSON.stringify(weightsArray)

        var repsArray = []
        for (var i = 0; i < numSets; i++) {
            repsArray.push((repsFields[i] && repsFields[i].text !== undefined) ? repsFields[i].text : "")
        }

        var repsVal = JSON.stringify(repsArray)
        var dateVal = selectedDate

        if (isEditMode) {
            DB.updateSession(sessionId, workoutVal, setsVal, repsVal, weightVal, dateVal)
            currentSessionId = sessionId
        } else {
            currentSessionId = DB.insertSession(workoutVal, setsVal, repsVal, weightVal, dateVal)
        }

        currentWorkout = workoutVal   
        // MARK AS SAVED
        isSaved = true

        // SET ACTIVE SESSION
        DB.ACTIVE_SESSION_ID = currentSessionId
        DB.ACTIVE_WORKOUT = currentWorkout

        console.log("Saved Session ID:", currentSessionId)
    }
}
              
               ]

    }

     
    Component.onCompleted: {

        console.log("Edit Mode:", isEditMode)

        if (isEditMode) {

            // Workout
            var workoutIndex = workoutSelector.model.indexOf(workout)
            if (workoutIndex !== -1)
                workoutSelector.selectedIndex = workoutIndex

            // Sets
            var setsIndex = setSelector.model.indexOf(sets)
            if (setsIndex !== -1)
                setSelector.selectedIndex = setsIndex

            // Weights
            if (weight && weight !== "") {
                weightsArray = JSON.parse(weight)
            } else {
                weightsArray = []
            }

            // Reps
            if (reps && reps !== "") {
                repsArray = JSON.parse(reps)
            } else {
                repsArray = []
            }

            // Wait for UI
          

            // Date
            if (date) {
                selectedDate = date
            }
        }

        formReady = true
    }

    Flickable {
        anchors.fill: parent
        anchors.topMargin: header.height + units.gu(2)

        Column {
            width: parent.width
            spacing: units.gu(2)

            anchors {
                left: parent.left
                right: parent.right
                margins: units.gu(2)
            }

            // Workout
            Label { text: "Select Workout" }

            OptionSelector {
                id: workoutSelector
                model: [
                    "Dumbbell Bench Press",
                    "Push Ups",
                    "Squats",
                    "Deadlift",
                    "Default"
                ]
                onSelectedIndexChanged: {
                    if (createSessionPage.formReady)
                        createSessionPage.isSaved = false
                }
            }

            // Sets
            Label { text: "No. of sets" }

            OptionSelector {
                id: setSelector
                model: ["1","2","3","4","5"]
                onSelectedIndexChanged: {
    weightFields = []
    repsFields = []
    if (createSessionPage.formReady)
        createSessionPage.isSaved = false
}
            }

            // Weights and Reps
            Column {
                width: parent.width

                Repeater {
                    model: parseInt(setSelector.model[setSelector.selectedIndex])

                    Column {
                        width: parent.width
                        spacing: units.gu(1)

                        Label {
                            text: "Set " + (index + 1)
                            font.bold: true
                        }

                        Row {
                            width: parent.width
                            spacing: units.gu(2)

                            Column {
                                width: (parent.width - units.gu(2)) / 2
                                spacing: units.gu(0.5)
                                Label {
                                    text: "Weight (kg)"
                                    font.pixelSize: units.gu(1.4)
                                }
                                TextField {
                                    placeholderText: "Enter weight"
                                    width: parent.width
                                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                                    text: (isEditMode && weightsArray.length > index) ? weightsArray[index] : ""
                                    onTextChanged: {
                                        if (activeFocus)
                                            createSessionPage.isSaved = false
                                    }
                                    Component.onCompleted: {
                                        weightFields[index] = this
                                    }
                                    Component.onDestruction: {
                                        weightFields[index] = null
                                    }
                                }
                            }

                            Column {
                                width: (parent.width - units.gu(2)) / 2
                                spacing: units.gu(0.5)
                                Label {
                                    text: "Reps"
                                    font.pixelSize: units.gu(1.4)
                                }
                                TextField {
                                    placeholderText: "Enter reps"
                                    width: parent.width
                                    inputMethodHints: Qt.ImhDigitsOnly
                                    text: (isEditMode && repsArray.length > index) ? repsArray[index] : ""
                                    onTextChanged: {
                                        if (activeFocus)
                                            createSessionPage.isSaved = false
                                    }
                                    Component.onCompleted: {
                                        repsFields[index] = this
                                    }
                                    Component.onDestruction: {
                                        repsFields[index] = null
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Date
            Label { text: "Select Date" }

            Button {
                id: dateButton

                text: selectedDate === "" ?
                      "Select Date" : Qt.formatDate(new Date(selectedDate), "MM/dd/yyyy")

                onClicked: {
                    PopupUtils.open(datePickerPopover, dateButton)
                }
            }

            // Start button
            Button {
                text: "Start Session"
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#b4dff0"

                onClicked: {
                    if (!isSaved || currentSessionId === -1) {
                        PopupUtils.open(saveDialog)
                        return
                    }

                    navigateToActiveSession()
                }
            }
        }
    }

    
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
                    text: "OK"
                    anchors.horizontalCenter: parent.horizontalCenter

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

    
    Component {
        id: saveDialog

        Dialog {
            id: dialog
            title: "Save Session First"

            Column {
                spacing: units.gu(2)

                Label {

                    width: parent.width
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignJustify
        text: i18n.tr("Please save the session using the Save icon before starting.")
                }

                Row {
                    spacing: units.gu(2)
                    anchors.horizontalCenter: parent.horizontalCenter

                    Button {
                        text: "OK"
                        color: "#b4dff0"
                        onClicked: PopupUtils.close(dialog)
                    }
                }
            }
        }
    }
}
