import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtQuick.Layouts 1.3

Page {
    id: createSessionPage

    property string selectedDate: ""

    header: PageHeader {
        title: "Create New Session"

        StyleHints {
            foregroundColor: "white"
            backgroundColor: "#f78787"
        }
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
                text: "Select Workout"
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
                text: "No. of sets"
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
                text: "Date"
            }

            Button {
                id: dateButton
                text: selectedDate === "" ? "Select Date" : selectedDate

                onClicked: {
                    PopupUtils.open(DateDialog)
                }
            }

            // Start session button
            Button {
                text: "Start Session"
                anchors.horizontalCenter: parent.horizontalCenter

                onClicked: {

                    console.log("Workout:",
                        workoutSelector.model[workoutSelector.selectedIndex])

                    console.log("Sets:",
                        setSelector.model[setSelector.selectedIndex])

                    console.log("Date:", selectedDate)
                }
            }
        }
    }

   
}