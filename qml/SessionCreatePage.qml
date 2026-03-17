import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Pickers 1.3
import QtQuick.Layouts 1.3
import "database.js" as DB

Page {
    id: createSessionPage

    property string selectedDate: ""

    header: PageHeader {
        title: i18n.tr("Create New Session")

        StyleHints {
            foregroundColor: "white"
            backgroundColor: '#f78787'
        }

        trailingActionBar.numberOfSlots: 2
            trailingActionBar.actions: [
               
              
               Action {
    iconName: "save"
    text: i18n.tr("Save Session")

    // onTriggered: {
    //     pageStack.push(Qt.resolvedUrl("AddSessionPage.qml"))
    // }
},

            Action {
    iconName: "edit"
    text: "Edit Session"

    // onTriggered: {
    //     pageStack.push(Qt.resolvedUrl("AddSessionPage.qml"))
    // }
} ]
    }

    Flickable {
        anchors.fill: parent
        anchors.topMargin: header.height + units.gu(2)

        Column {
            id: column
            width: parent.width
            spacing: units.gu(2)

            anchors {
                left: parent.left
                right: parent.right
                margins: units.gu(2)
            }
  
            // Workout selection
            Label {
                text: i18n.tr("Select Workout")
            }

            OptionSelector {
                id: workoutSelector
                model: [
                    "Dumbbell Bench Press",
                    "Push Ups",
                    "Squats",
                    "Deadlift"
                ]
            }

            // Number of sets
            Label {
                text: i18n.tr("No. of sets")
            }

            OptionSelector {
                id: setSelector
                model: ["1","2","3","4","5"]
            }



            // Dynamic weight inputs
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
                        }
                    }
                }
            }

            // Date selection
            Label {
                text: i18n.tr("Select Date")
            }

         

          Button {
    id: dateButton
    text: selectedDate === "" ? "Date" : selectedDate

    onClicked: {
        PopupUtils.open(datePickerPopover, dateButton)
    }
}




            // Start session button
          Button {
    text: "Start Session"
    anchors.horizontalCenter: parent.horizontalCenter

    onClicked: {
        PopupUtils.open(saveDialog)
    }
}
            // Date Picker Dialog
  
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
                    selectedDate = picker.date.toLocaleDateString(Qt.locale(), "MM/ d/ yyyy")
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

                    onClicked: {
                        PopupUtils.close(dialog)
                    }
                }

                Button {
                    text: "Save & Start"


       onClicked: {

    var workout = workoutSelector.model[workoutSelector.selectedIndex]
    var sets = setSelector.model[setSelector.selectedIndex]
    var weight = "multiple"
    var date = selectedDate

    console.log("Saving date:", date)

    DB.insertSession(workout, sets, weight, date)

    PopupUtils.close(dialog)

    pageStack.push(Qt.resolvedUrl("ActiveSessionPage.qml"))
}

                    // onClicked: {

                    //     var workoutName =
                    //         workoutSelector.model[workoutSelector.selectedIndex]

                    //     var sets =
                    //         setSelector.model[setSelector.selectedIndex]

                    //     console.log("Workout:", workoutName)
                    //     console.log("Sets:", sets)
                    //     console.log("Date:", selectedDate)

                    //     PopupUtils.close(dialog)

                    //     pageStack.push(Qt.resolvedUrl("ActiveSessionPage.qml"))
                    // }
                }
            }
        }
    }
}

    }

   
}