import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Pickers 1.3
import QtQuick.Layouts 1.3
 import "database.js" as DB

Page {
    id: createSessionPage
   

    property string selectedDate: ""
    property bool isEditing: false

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
    text: i18n.tr("Save Settings")
    enabled: isEditing

    onTriggered: {
        var weight = setWeight.model[setWeight.selectedIndex]
        var kcal = workoutSelector.model[workoutSelector.selectedIndex]
        var workouts = setSelector.model[setSelector.selectedIndex]
        
        DB.upsertSettings(weight, kcal, workouts, selectedDate)
        isEditing = false
        PopupUtils.open(successDialog)
    }
},

            Action {
    iconName: "edit"
    text: i18n.tr("Edit Settings")
    enabled: !isEditing

    onTriggered: {
        isEditing = true
    }
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
                enabled: isEditing
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
                enabled: isEditing
            }

            // Number of sets
            Label {
                text: i18n.tr("No. of workout")
            }

            OptionSelector {
                id: setSelector
                model: ["1","2","3","4","5"]
                enabled: isEditing
            }

            // Dynamic weight inputs
            

            // Date selection
            Label {
                text: i18n.tr("Select Date")
            }

         

          Button {
    id: dateButton
    text: selectedDate === "" ? "Date" : selectedDate
    enabled: isEditing

    onClicked: {
        PopupUtils.open(datePickerPopover, dateButton)
    }
}




            // Start session button
          Button {
    text: i18n.tr("Save")
    anchors.horizontalCenter: parent.horizontalCenter
    enabled: isEditing

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

                    onClicked: {
                        var weight = setWeight.model[setWeight.selectedIndex]
                        var kcal = workoutSelector.model[workoutSelector.selectedIndex]
                        var workouts = setSelector.model[setSelector.selectedIndex]
                        
                        DB.upsertSettings(weight, kcal, workouts, selectedDate)
                        isEditing = false
                        PopupUtils.close(dialog)
                        PopupUtils.open(successDialog)
                    }
                }
            }
        }
    }
}

Component {
    id: successDialog

    Dialog {
        id: dialog
        title: i18n.tr("Success")

        Column {
            spacing: units.gu(2)
            Label {
                text: i18n.tr("Settings saved successfully")
                width: parent.width
                wrapMode: Text.WordWrap
            }
            Button {
                text: i18n.tr("OK")
                onClicked: PopupUtils.close(dialog)
            }
        }
    }
}

Component.onCompleted: {
    var settings = DB.getSettings()
    if (settings) {
        var weightIdx = setWeight.model.indexOf(settings.weight)
        if (weightIdx !== -1) setWeight.selectedIndex = weightIdx

        var kcalIdx = workoutSelector.model.indexOf(settings.kcal_target)
        if (kcalIdx !== -1) workoutSelector.selectedIndex = kcalIdx

        var workoutsIdx = setSelector.model.indexOf(settings.num_workouts)
        if (workoutsIdx !== -1) setSelector.selectedIndex = workoutsIdx

        selectedDate = settings.date
    }
}

    }

   
}