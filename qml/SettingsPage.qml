import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Pickers 1.3
import QtQuick.Layouts 1.3

Page {
    id: createSessionPage

    property string selectedDate: ""

    header: PageHeader {
        title: "Settings"

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
    text: i18n.tr("Edit Session")

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
            Label {
                text: i18n.tr("Current Weight")
            }

            OptionSelector {
                id: setWeight
                model: ["50","55","60","65","70", "75", "80"]
            }

            // Workout selection
            Label {
                text: i18n.tr("Kcal should burn")
            }

            OptionSelector {
                id: workoutSelector
                model: [
                    "300",
                    "400",
                    "500",
                    "600",
                    "700",
                    "800"
                ]
            }

            // Number of sets
            Label {
                text: i18n.tr("No. of workout")
            }

            OptionSelector {
                id: setSelector
                model: ["1","2","3","4","5"]
            }

            // Dynamic weight inputs
            

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
    text: i18n.tr("Save")
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
                text: i18n.tr("OK")
                anchors.horizontalCenter: parent.horizontalCenter

                onClicked: {
                    selectedDate = picker.date.toLocaleDateString(Qt.locale(), "MMMM d, yyyy")
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
        title: "Save Settings"

        Column {
            spacing: units.gu(2)

            Label {
               

                width: parent.width
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignJustify
        text: i18n.tr("Save the settings before starting new session")
            }

            Row {
                spacing: units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter

                Button {
                    text: i18n.tr("Cancel")

                    onClicked: {
                        PopupUtils.close(dialog)
                    }
                }

                Button {
                    text: i18n.tr("Save")

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