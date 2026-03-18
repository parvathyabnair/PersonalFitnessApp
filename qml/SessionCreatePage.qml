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

    property string workout: ""
    property string sets: ""
    property string weight: ""
    property string date: ""
 
    property var weightsArray: []
    property var weightFields: []
    property string selectedDate: ""

    header: PageHeader {
        title: isEditMode ? "Edit Session" : "Create New Session"

        StyleHints {
            foregroundColor: "white"
            backgroundColor: "#f78787"
        }
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

            // Wait for UI
          

            // Date
            if (date) {
                selectedDate = date
            }
        }
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
                    "Deadlift"
                ]
            }

            // Sets
            Label { text: "No. of sets" }

            OptionSelector {
                id: setSelector
                model: ["1","2","3","4","5"]
                onSelectedIndexChanged: {
    weightFields = []
}
            }

            // Weights
            Column {
                width: parent.width

                Repeater {
                    model: parseInt(setSelector.model[setSelector.selectedIndex])

                    Column {
                        width: parent.width
                        spacing: units.gu(1)

                        Label {
                            text: "Set " + (index + 1) + " Weight (kg)"
                        }

                      TextField {
    placeholderText: "Enter weight"

    
    text: (isEditMode && weightsArray.length > index) ? weightsArray[index] : ""

    Component.onCompleted: {
        weightFields[index] = this
    }

    Component.onDestruction: {
        weightFields[index] = null
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
                      "Select Date" :
                      new Date(selectedDate)
                      .toLocaleDateString(Qt.locale(), "MMMM d, yyyy")

                onClicked: {
                    PopupUtils.open(datePickerPopover, dateButton)
                }
            }

            // Start button
            Button {
                text: "Start Session"
                anchors.horizontalCenter: parent.horizontalCenter

                onClicked: {
                    PopupUtils.open(saveDialog)
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
            title: "Save Session"

            Column {
                spacing: units.gu(2)

                Label {
                    text: "Save the session before starting"
                    wrapMode: Text.WordWrap
                }

                Row {
                    spacing: units.gu(2)
                    anchors.horizontalCenter: parent.horizontalCenter

                    Button {
                        text: "Cancel"
                        onClicked: PopupUtils.close(dialog)
                    }

                    Button {
                        text: "Save & Start"

                        onClicked: {

                            var workoutVal =
                                workoutSelector.model[workoutSelector.selectedIndex]

                            var setsVal =
                                setSelector.model[setSelector.selectedIndex]

                            // Collect weights
                            weightsArray = []

                            for (var i = 0; i < weightFields.length; i++) {
                                weightsArray.push(weightFields[i].text)
                            }

                            var weightString = JSON.stringify(weightsArray)
                            var dateVal = selectedDate

                            console.log("Saving weights:", weightString)
                            console.log("Saving date:", dateVal)

                            if (isEditMode) {

                                DB.updateSession(
                                    sessionId,
                                    workoutVal,
                                    setsVal,
                                    weightString,
                                    dateVal
                                )

                            } else {

                                DB.insertSession(
                                    workoutVal,
                                    setsVal,
                                    weightString,
                                    dateVal
                                )
                            }

                            PopupUtils.close(dialog)
pageLayout.addPageToNextColumn(pageLayout.primaryPage,Qt.resolvedUrl("ActiveSessionPage.qml"),
    {
        pageLayout: pageLayout,   
        sets: setsVal,
        weights: weightsArray
    }
)                           
                        }
                    }
                }
            }
        }
    }
}