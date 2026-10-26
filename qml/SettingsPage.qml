import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Pickers 1.3
import QtQuick.Layouts 1.3
import "database.js" as DB

Page {
    id: settingsPage
    anchors.fill: parent

    property string selectedDate: ""

    function saveSettings() {
        var weight = setWeight.model[setWeight.selectedIndex]
        var kcal = workoutSelector.model[workoutSelector.selectedIndex]
        var workouts = setSelector.model[setSelector.selectedIndex]
        var goalWeight = goalWeightField.text.trim()
        var gender = femalePill.selected ? "Female" : "Male"
        var dateVal = selectedDate !== "" ? selectedDate : Qt.formatDate(new Date(), "MM/dd/yyyy")
        var height = heightField.text.trim() !== "" ? heightField.text.trim() : "175"
        var age = ageField.text.trim() !== "" ? ageField.text.trim() : "25"
        
        DB.upsertSettings(weight, kcal, workouts, dateVal, goalWeight, gender, height, age)
        PopupUtils.open(successDialog)
    }

    header: PageHeader {
        title: i18n.tr("Settings")

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
                onTriggered: saveSettings()
            }
        ]
    }

    Flickable {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        contentWidth: width
        contentHeight: column.height + units.gu(6)
        clip: true
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.DragOverBounds

        Column {
            id: column
            width: parent.width - units.gu(3)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: units.gu(2)
            topPadding: units.gu(2)
            bottomPadding: units.gu(3)

            // PROFILE SECTION CARD
            Rectangle {
                width: parent.width
                height: profileColumn.height + units.gu(3)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)

                Column {
                    id: profileColumn
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: units.gu(1.5)
                    spacing: units.gu(1.5)

                    Label {
                        text: i18n.tr("Personal Profile")
                        font.bold: true
                        font.pixelSize: units.gu(1.8)
                        color: root.textPrimaryColor
                    }

                    // Gender Selection Pills
                    Column {
                        width: parent.width
                        spacing: units.gu(0.6)

                        Label {
                            text: i18n.tr("Gender")
                            font.bold: true
                            font.pixelSize: units.gu(1.4)
                            color: root.textSecondaryColor
                        }

                        Row {
                            width: parent.width
                            spacing: units.gu(1.5)

                            Rectangle {
                                id: malePill
                                width: (parent.width - units.gu(1.5)) / 2
                                height: units.gu(4.5)
                                radius: units.dp(8)
                                property bool selected: true
                                color: selected ? root.primaryColor : (root.isDarkMode ? "#2C2D32" : "#F8F9FA")
                                border.color: selected ? root.primaryColor : root.cardBorderColor
                                border.width: units.dp(1)

                                Row {
                                    anchors.centerIn: parent
                                    spacing: units.gu(0.8)

                                    Label {
                                        text: "♂"
                                        font.bold: true
                                        font.pixelSize: units.gu(1.6)
                                        color: malePill.selected ? "white" : root.textPrimaryColor
                                    }

                                    Label {
                                        text: i18n.tr("Male")
                                        font.bold: malePill.selected
                                        font.pixelSize: units.gu(1.4)
                                        color: malePill.selected ? "white" : root.textPrimaryColor
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        malePill.selected = true
                                        femalePill.selected = false
                                    }
                                }
                            }

                            Rectangle {
                                id: femalePill
                                width: (parent.width - units.gu(1.5)) / 2
                                height: units.gu(4.5)
                                radius: units.dp(8)
                                property bool selected: false
                                color: selected ? root.primaryColor : (root.isDarkMode ? "#2C2D32" : "#F8F9FA")
                                border.color: selected ? root.primaryColor : root.cardBorderColor
                                border.width: units.dp(1)

                                Row {
                                    anchors.centerIn: parent
                                    spacing: units.gu(0.8)

                                    Label {
                                        text: "♀"
                                        font.bold: true
                                        font.pixelSize: units.gu(1.6)
                                        color: femalePill.selected ? "white" : root.textPrimaryColor
                                    }

                                    Label {
                                        text: i18n.tr("Female")
                                        font.bold: femalePill.selected
                                        font.pixelSize: units.gu(1.4)
                                        color: femalePill.selected ? "white" : root.textPrimaryColor
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        femalePill.selected = true
                                        malePill.selected = false
                                    }
                                }
                            }
                        }
                    }

                    // Current Weight
                    Column {
                        width: parent.width
                        spacing: units.gu(0.6)

                        Label {
                            text: i18n.tr("Current Weight (kg)")
                            font.bold: true
                            font.pixelSize: units.gu(1.4)
                            color: root.textSecondaryColor
                        }

                        OptionSelector {
                            id: setWeight
                            model: ["45", "50", "55", "60", "65", "70", "75", "80", "85", "90", "95", "100"]
                        }
                    }

                    // Goal Weight
                    Column {
                        width: parent.width
                        spacing: units.gu(0.6)

                        Label {
                            text: i18n.tr("Target Goal Weight (kg)")
                            font.bold: true
                            font.pixelSize: units.gu(1.4)
                            color: root.textSecondaryColor
                        }

                        TextField {
                            id: goalWeightField
                            placeholderText: i18n.tr("e.g. 65")
                            width: parent.width
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                        }
                    }

                    // Height and Age Inputs
                    Row {
                        width: parent.width
                        spacing: units.gu(1.5)

                        Column {
                            width: (parent.width - units.gu(1.5)) / 2
                            spacing: units.gu(0.6)

                            Label {
                                text: i18n.tr("Height (cm)")
                                font.bold: true
                                font.pixelSize: units.gu(1.4)
                                color: root.textSecondaryColor
                            }

                            TextField {
                                id: heightField
                                placeholderText: "175"
                                text: "175"
                                width: parent.width
                                inputMethodHints: Qt.ImhFormattedNumbersOnly
                            }
                        }

                        Column {
                            width: (parent.width - units.gu(1.5)) / 2
                            spacing: units.gu(0.6)

                            Label {
                                text: i18n.tr("Age (years)")
                                font.bold: true
                                font.pixelSize: units.gu(1.4)
                                color: root.textSecondaryColor
                            }

                            TextField {
                                id: ageField
                                placeholderText: "25"
                                text: "25"
                                width: parent.width
                                inputMethodHints: Qt.ImhFormattedNumbersOnly
                            }
                        }
                    }
                }
            }

            // METABOLIC & BODY COMPOSITION PROFILE CARD
            Rectangle {
                id: metabolicCard
                width: parent.width
                height: metabolicCol.height + units.gu(3)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)

                readonly property var currentBmi: {
                    var w = (setWeight && setWeight.selectedIndex >= 0) ? setWeight.model[setWeight.selectedIndex] : 70;
                    var h = (heightField && heightField.text) ? heightField.text : "175";
                    return DB.calculateBMI(w, h);
                }
                readonly property int currentBmr: {
                    var w = (setWeight && setWeight.selectedIndex >= 0) ? setWeight.model[setWeight.selectedIndex] : 70;
                    var h = (heightField && heightField.text) ? heightField.text : "175";
                    var a = (ageField && ageField.text) ? ageField.text : "25";
                    var g = (femalePill && femalePill.selected) ? "Female" : "Male";
                    return DB.calculateBMR(w, h, a, g);
                }

                Column {
                    id: metabolicCol
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
                                text: "🩺"
                                font.pixelSize: units.gu(1.8)
                            }

                            Label {
                                text: i18n.tr("Metabolic & Body Telemetry")
                                font.bold: true
                                font.pixelSize: units.gu(1.6)
                                color: root.textPrimaryColor
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            text: i18n.tr("Mifflin-St Jeor")
                            font.pixelSize: units.gu(1.1)
                            color: root.textSecondaryColor
                        }
                    }

                    // BMI and BMR side-by-side
                    Row {
                        width: parent.width
                        spacing: units.gu(1.5)

                        // BMI card
                        Rectangle {
                            width: (parent.width - units.gu(1.5)) / 2
                            height: units.gu(9)
                            radius: units.dp(10)
                            color: root.isDarkMode ? "#25262B" : "#F8F9FA"

                            Column {
                                anchors.centerIn: parent
                                spacing: units.gu(0.4)

                                Row {
                                    spacing: units.gu(0.5)
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Label {
                                        text: metabolicCard.currentBmi.bmi
                                        font.bold: true
                                        font.pixelSize: units.gu(2.4)
                                        color: root.textPrimaryColor
                                    }

                                    Label {
                                        text: "BMI"
                                        font.pixelSize: units.gu(1.2)
                                        color: root.textSecondaryColor
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: units.gu(0.3)
                                    }
                                }

                                Rectangle {
                                    height: units.gu(2.4)
                                    width: bmiStatusLabel.width + units.gu(1.6)
                                    radius: height / 2
                                    color: metabolicCard.currentBmi.color
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Label {
                                        id: bmiStatusLabel
                                        anchors.centerIn: parent
                                        text: metabolicCard.currentBmi.status
                                        font.bold: true
                                        font.pixelSize: units.gu(1.0)
                                        color: "white"
                                    }
                                }
                            }
                        }

                        // BMR card
                        Rectangle {
                            width: (parent.width - units.gu(1.5)) / 2
                            height: units.gu(9)
                            radius: units.dp(10)
                            color: root.isDarkMode ? "#25262B" : "#F8F9FA"

                            Column {
                                anchors.centerIn: parent
                                spacing: units.gu(0.3)

                                Row {
                                    spacing: units.gu(0.4)
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Label {
                                        text: metabolicCard.currentBmr.toString()
                                        font.bold: true
                                        font.pixelSize: units.gu(2.4)
                                        color: "#38BDF8"
                                    }

                                    Label {
                                        text: "kcal"
                                        font.pixelSize: units.gu(1.2)
                                        color: root.textSecondaryColor
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: units.gu(0.3)
                                    }
                                }

                                Label {
                                    text: i18n.tr("Resting BMR (1.0 MET)")
                                    font.pixelSize: units.gu(1.0)
                                    color: root.textSecondaryColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }
                    }

                    // Guidance Note
                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: i18n.tr("At 1.0 MET baseline rest, your body requires ~") + metabolicCard.currentBmr + i18n.tr(" kcal/day. Adding physical workouts at higher METs accelerates fat loss and conditioning.")
                        font.pixelSize: units.gu(1.1)
                        color: root.textSecondaryColor
                    }
                }
            }

            // FITNESS TARGETS SECTION CARD
            Rectangle {
                width: parent.width
                height: targetsColumn.height + units.gu(3)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)

                Column {
                    id: targetsColumn
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: units.gu(1.5)
                    spacing: units.gu(1.5)

                    Label {
                        text: i18n.tr("Daily & Weekly Targets")
                        font.bold: true
                        font.pixelSize: units.gu(1.8)
                        color: root.textPrimaryColor
                    }

                    // Kcal Target
                    Column {
                        width: parent.width
                        spacing: units.gu(0.6)

                        Label {
                            text: i18n.tr("Daily Calorie Burn Target (kcal)")
                            font.bold: true
                            font.pixelSize: units.gu(1.4)
                            color: root.textSecondaryColor
                        }

                        OptionSelector {
                            id: workoutSelector
                            model: [
                                "150",
                                "250",
                                "300",
                                "400",
                                "500",
                                "600",
                                "700",
                                "800",
                                "1000"
                            ]
                        }
                    }

                    // Number of Workouts Target
                    Column {
                        width: parent.width
                        spacing: units.gu(0.6)

                        Label {
                            text: i18n.tr("Target Workouts per Week")
                            font.bold: true
                            font.pixelSize: units.gu(1.4)
                            color: root.textSecondaryColor
                        }

                        OptionSelector {
                            id: setSelector
                            model: ["1", "2", "3", "4", "5", "6", "7"]
                        }
                    }

                    // Target Date
                    Column {
                        width: parent.width
                        spacing: units.gu(0.6)

                        Label {
                            text: i18n.tr("Goal Target Date")
                            font.bold: true
                            font.pixelSize: units.gu(1.4)
                            color: root.textSecondaryColor
                        }

                        Button {
                            id: dateButton
                            text: selectedDate === "" ? i18n.tr("Select Goal Date") : selectedDate
                            color: root.cardBorderColor
                            width: parent.width
                            height: units.gu(4.5)

                            onClicked: {
                                PopupUtils.open(datePickerPopover, dateButton)
                            }
                        }
                    }
                }
            }

            // SAVE SETTINGS BUTTON
            Button {
                text: i18n.tr("Save Settings")
                color: root.primaryColor
                width: parent.width
                height: units.gu(5)

                onClicked: saveSettings()
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
                        selectedDate = Qt.formatDate(picker.date, "MM/dd/yyyy")
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
            id: dialog
            title: i18n.tr("Saved! 🎉")

            Column {
                spacing: units.gu(2)
                Label {
                    text: i18n.tr("Your fitness profile and targets have been saved successfully.")
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: root.textPrimaryColor
                }
                Button {
                    text: i18n.tr("OK")
                    color: root.primaryColor
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: units.gu(14)
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

            selectedDate = settings.date || ""
            goalWeightField.text = settings.goal_weight || ""
            
            if (settings.gender === "Female") {
                femalePill.selected = true
                malePill.selected = false
            } else {
                malePill.selected = true
                femalePill.selected = false
            }

            if (settings.height) {
                heightField.text = settings.height
            }
            if (settings.age) {
                ageField.text = settings.age
            }
        }
    }
}