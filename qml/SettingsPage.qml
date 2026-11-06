import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Pickers 1.3
import QtQuick.Layouts 1.3
import "components"
import "database.js" as DB

Page {
    id: settingsPage
    anchors.fill: parent

    property var pageLayout
    property bool isViewMode: true
    property string selectedDate: ""
    property string currentWeightVal: "70"
    property string kcalTargetVal: "500"
    property string goalWeightVal: ""
    property string genderVal: "Male"
    property string heightVal: "175"
    property string ageVal: "25"

    PropertyAnimation {
        id: scrollAnim
        target: settingsFlickable
        property: "contentY"
        duration: 200
        easing.type: Easing.OutQuad
    }

    function ensureVisible(item) {
        if (!item || !settingsFlickable) return
        var pos = item.mapToItem(settingsFlickable.contentItem, 0, 0)
        var itemY = pos.y
        var itemHeight = item.height
        var viewportHeight = settingsFlickable.height
        var margin = units.gu(4)

        var newContentY = settingsFlickable.contentY
        if (itemY - margin < settingsFlickable.contentY) {
            newContentY = Math.max(0, itemY - margin)
        } else if (itemY + itemHeight + margin > settingsFlickable.contentY + viewportHeight) {
            var targetY = itemY + itemHeight + margin - viewportHeight
            var maxY = Math.max(0, settingsFlickable.contentHeight - viewportHeight)
            newContentY = Math.min(maxY, targetY)
        }

        if (Math.abs(newContentY - settingsFlickable.contentY) > 1) {
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
            if (kcalInputField && kcalInputField.activeFocus) {
                ensureVisible(kcalInputField)
            } else if (weightInputField && weightInputField.activeFocus) {
                ensureVisible(weightInputField)
            } else if (goalWeightField && goalWeightField.activeFocus) {
                ensureVisible(goalWeightField)
            } else if (heightField && heightField.activeFocus) {
                ensureVisible(heightField)
            } else if (ageField && ageField.activeFocus) {
                ensureVisible(ageField)
            }
        }
    }


    function loadSettings() {
        var settings = DB.getSettings()
        if (settings) {
            var w = settings.weight ? String(settings.weight).trim() : "70"
            currentWeightVal = w
            if (weightInputField) weightInputField.text = w

            var kc = settings.kcal_target ? String(settings.kcal_target) : "500"
            kcalTargetVal = kc
            if (kcalInputField) kcalInputField.text = kc

            selectedDate = settings.date || ""

            var gw = settings.goal_weight || ""
            goalWeightVal = gw
            if (goalWeightField) goalWeightField.text = gw
            
            genderVal = settings.gender === "Female" ? "Female" : "Male"
            if (femalePill && malePill) {
                if (settings.gender === "Female") {
                    femalePill.selected = true
                    malePill.selected = false
                } else {
                    malePill.selected = true
                    femalePill.selected = false
                }
            }

            var h = settings.height ? String(settings.height) : "175"
            heightVal = h
            if (heightField) heightField.text = h

            var a = settings.age ? String(settings.age) : "25"
            ageVal = a
            if (ageField) ageField.text = a
        }
    }

    function saveSettings() {
        var weight = (weightInputField && weightInputField.text.trim() !== "") ? weightInputField.text.trim() : (currentWeightVal || "70")
        currentWeightVal = weight
        var kcal = (kcalInputField && kcalInputField.text.trim() !== "") ? kcalInputField.text.trim() : (kcalTargetVal || "500")
        kcalTargetVal = kcal
        var currentSettings = DB.getSettings()
        var workouts = (currentSettings && currentSettings.num_workouts) ? currentSettings.num_workouts : "3"
        var goalWeight = (goalWeightField) ? goalWeightField.text.trim() : goalWeightVal
        goalWeightVal = goalWeight
        var gender = (femalePill && femalePill.selected) ? "Female" : genderVal
        genderVal = gender
        var dateVal = selectedDate !== "" ? selectedDate : Qt.formatDate(new Date(), "MM/dd/yyyy")
        selectedDate = dateVal
        var height = (heightField && heightField.text.trim() !== "") ? heightField.text.trim() : (heightVal || "175")
        heightVal = height
        var age = (ageField && ageField.text.trim() !== "") ? ageField.text.trim() : (ageVal || "25")
        ageVal = age
        
        DB.upsertSettings(weight, kcal, workouts, dateVal, goalWeight, gender, height, age)
        isViewMode = true
        PopupUtils.open(successDialog)
    }

    header: PageHeader {
        title: isViewMode ? i18n.tr("Settings Profile") : i18n.tr("Edit Settings")

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
                        pageLayout.removePages(settingsPage)
                    }
                }
            }
        ]

        trailingActionBar.numberOfSlots: isViewMode ? 1 : 2
        trailingActionBar.actions: isViewMode ? [editHeaderAction] : [saveHeaderAction, cancelHeaderAction]

        Action {
            id: editHeaderAction
            iconName: "edit"
            text: i18n.tr("Edit")
            visible: isViewMode
            onTriggered: {
                isViewMode = false
            }
        }

        Action {
            id: saveHeaderAction
            iconName: "save"
            text: i18n.tr("Save")
            visible: !isViewMode
            onTriggered: saveSettings()
        }

        Action {
            id: cancelHeaderAction
            iconName: "close"
            text: i18n.tr("Cancel")
            visible: !isViewMode
            onTriggered: {
                loadSettings()
                isViewMode = true
            }
        }
    }

    Flickable {
        id: settingsFlickable
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Qt.inputMethod.visible ? (Qt.inputMethod.keyboardRectangle.height > 0 ? Qt.inputMethod.keyboardRectangle.height : units.gu(30)) : 0
        anchors.left: parent.left
        anchors.right: parent.right
        contentWidth: width
        contentHeight: column.height + units.gu(10)
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
            id: column
            width: parent.width - units.gu(3)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: units.gu(2)
            topPadding: units.gu(2)
            bottomPadding: units.gu(3)

            // PROFILE SECTION CARD
            Rectangle {
                width: parent.width
                height: (isViewMode ? viewProfileCol.height : profileColumn.height) + units.gu(3)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)

                Column {
                    id: viewProfileCol
                    visible: isViewMode
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: units.gu(1.5)
                    spacing: units.gu(1.5)

                    RowLayout {
                        width: parent.width

                        Label {
                            text: i18n.tr("Personal Profile")
                            font.bold: true
                            font.pixelSize: units.gu(1.8)
                            color: root.textPrimaryColor
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            height: units.gu(3)
                            width: genderBadgeRow.width + units.gu(2)
                            radius: height / 2
                            color: root.primaryColor

                            Row {
                                id: genderBadgeRow
                                anchors.centerIn: parent
                                spacing: units.gu(0.5)

                                Label {
                                    text: settingsPage.genderVal === "Female" ? "♀" : "♂"
                                    font.bold: true
                                    font.pixelSize: units.gu(1.3)
                                    color: "white"
                                }

                                Label {
                                    text: settingsPage.genderVal === "Female" ? i18n.tr("Female") : i18n.tr("Male")
                                    font.bold: true
                                    font.pixelSize: units.gu(1.2)
                                    color: "white"
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: units.gu(1.5)

                        Rectangle {
                            width: (parent.width - units.gu(1.5)) / 2
                            height: units.gu(8)
                            radius: units.dp(10)
                            color: root.isDarkMode ? "#25262B" : "#F8F9FA"

                            Column {
                                anchors.centerIn: parent
                                spacing: units.gu(0.4)

                                Label {
                                    text: i18n.tr("Current Weight")
                                    font.pixelSize: units.gu(1.2)
                                    color: root.textSecondaryColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Label {
                                    text: (settingsPage.currentWeightVal !== "" ? settingsPage.currentWeightVal : "70") + " kg"
                                    font.bold: true
                                    font.pixelSize: units.gu(2.0)
                                    color: root.primaryColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }

                        Rectangle {
                            width: (parent.width - units.gu(1.5)) / 2
                            height: units.gu(8)
                            radius: units.dp(10)
                            color: root.isDarkMode ? "#25262B" : "#F8F9FA"

                            Column {
                                anchors.centerIn: parent
                                spacing: units.gu(0.4)

                                Label {
                                    text: i18n.tr("Goal Weight")
                                    font.pixelSize: units.gu(1.2)
                                    color: root.textSecondaryColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Label {
                                    text: settingsPage.goalWeightVal !== "" ? (settingsPage.goalWeightVal + " kg") : i18n.tr("Not set")
                                    font.bold: true
                                    font.pixelSize: units.gu(2.0)
                                    color: settingsPage.goalWeightVal !== "" ? root.secondaryColor : root.textSecondaryColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: units.gu(1.5)

                        Rectangle {
                            width: (parent.width - units.gu(1.5)) / 2
                            height: units.gu(8)
                            radius: units.dp(10)
                            color: root.isDarkMode ? "#25262B" : "#F8F9FA"

                            Column {
                                anchors.centerIn: parent
                                spacing: units.gu(0.4)

                                Label {
                                    text: i18n.tr("Height")
                                    font.pixelSize: units.gu(1.2)
                                    color: root.textSecondaryColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Label {
                                    text: (settingsPage.heightVal !== "" ? settingsPage.heightVal : "175") + " cm"
                                    font.bold: true
                                    font.pixelSize: units.gu(2.0)
                                    color: root.textPrimaryColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }

                        Rectangle {
                            width: (parent.width - units.gu(1.5)) / 2
                            height: units.gu(8)
                            radius: units.dp(10)
                            color: root.isDarkMode ? "#25262B" : "#F8F9FA"

                            Column {
                                anchors.centerIn: parent
                                spacing: units.gu(0.4)

                                Label {
                                    text: i18n.tr("Age")
                                    font.pixelSize: units.gu(1.2)
                                    color: root.textSecondaryColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Label {
                                    text: (settingsPage.ageVal !== "" ? settingsPage.ageVal : "25") + " " + i18n.tr("years")
                                    font.bold: true
                                    font.pixelSize: units.gu(2.0)
                                    color: root.textPrimaryColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }
                    }
                }

                Column {
                    id: profileColumn
                    visible: !isViewMode
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

                        RowLayout {
                            width: parent.width
                            Label {
                                text: i18n.tr("Current Weight (kg)")
                                font.bold: true
                                font.pixelSize: units.gu(1.4)
                                color: root.textSecondaryColor
                            }
                            Item { Layout.fillWidth: true }
                            Label {
                                text: (weightInputField.text.trim() !== "" ? weightInputField.text.trim() : settingsPage.currentWeightVal) + " kg"
                                font.bold: true
                                font.pixelSize: units.gu(1.4)
                                color: root.primaryColor
                            }
                        }

                        TextField {
                            id: weightInputField
                            text: settingsPage.currentWeightVal
                            placeholderText: i18n.tr("e.g. 70")
                            width: parent.width
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            onTextChanged: {
                                if (text.trim() !== "") {
                                    settingsPage.currentWeightVal = text.trim()
                                }
                            }
                            onActiveFocusChanged: {
                                if (activeFocus) ensureVisibleTimer.restart()
                            }
                            onAccepted: {
                                focus = false
                                Qt.inputMethod.hide()
                            }
                        }

                        // Quick weight preset chips
                        Row {
                            spacing: units.gu(0.8)
                            width: parent.width

                            Repeater {
                                model: ["50", "60", "70", "80", "90", "100"]
                                Rectangle {
                                    height: units.gu(2.8)
                                    width: (parent.width - units.gu(4)) / 6
                                    radius: height / 2
                                    color: (weightInputField.text === modelData) ? root.primaryColor : root.cardBorderColor

                                    Label {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: (weightInputField.text === modelData) ? "white" : root.textPrimaryColor
                                        font.pixelSize: units.gu(1.1)
                                        font.bold: (weightInputField.text === modelData)
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            weightInputField.text = modelData
                                            settingsPage.currentWeightVal = modelData
                                        }
                                    }
                                }
                            }
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
                            onActiveFocusChanged: {
                                if (activeFocus) ensureVisibleTimer.restart()
                            }
                            onAccepted: {
                                focus = false
                                Qt.inputMethod.hide()
                            }
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
                                onActiveFocusChanged: {
                                    if (activeFocus) ensureVisibleTimer.restart()
                                }
                                onAccepted: {
                                    focus = false
                                    Qt.inputMethod.hide()
                                }
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
                                onActiveFocusChanged: {
                                    if (activeFocus) ensureVisibleTimer.restart()
                                }
                                onAccepted: {
                                    focus = false
                                    Qt.inputMethod.hide()
                                }
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
                    var w = (!isViewMode && weightInputField && weightInputField.text.trim() !== "") ? weightInputField.text.trim() : (settingsPage.currentWeightVal || "70");
                    var h = (!isViewMode && heightField && heightField.text) ? heightField.text : (settingsPage.heightVal || "175");
                    return DB.calculateBMI(w, h);
                }
                readonly property int currentBmr: {
                    var w = (!isViewMode && weightInputField && weightInputField.text.trim() !== "") ? weightInputField.text.trim() : (settingsPage.currentWeightVal || "70");
                    var h = (!isViewMode && heightField && heightField.text) ? heightField.text : (settingsPage.heightVal || "175");
                    var a = (!isViewMode && ageField && ageField.text) ? ageField.text : (settingsPage.ageVal || "25");
                    var g = (!isViewMode && femalePill && femalePill.selected) ? "Female" : (settingsPage.genderVal || "Male");
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
                                text: i18n.tr("Metabolic & Body Telemetry")
                                font.bold: true
                                font.pixelSize: units.gu(1.6)
                                color: root.textPrimaryColor
                            }
                        }

                        Item { Layout.fillWidth: true }

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
                                        color: root.secondaryColor
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
                height: (isViewMode ? viewTargetsCol.height : targetsColumn.height) + units.gu(3)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)

                Column {
                    id: viewTargetsCol
                    visible: isViewMode
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

                    Row {
                        width: parent.width
                        spacing: units.gu(1.5)

                        Rectangle {
                            width: (parent.width - units.gu(1.5)) / 2
                            height: units.gu(8)
                            radius: units.dp(10)
                            color: root.isDarkMode ? "#25262B" : "#F8F9FA"

                            Column {
                                anchors.centerIn: parent
                                spacing: units.gu(0.4)

                                Label {
                                    text: i18n.tr("Daily Burn Target")
                                    font.pixelSize: units.gu(1.2)
                                    color: root.textSecondaryColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Label {
                                    text: (settingsPage.kcalTargetVal !== "" ? settingsPage.kcalTargetVal : "500") + " kcal"
                                    font.bold: true
                                    font.pixelSize: units.gu(2.0)
                                    color: root.secondaryColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }

                        Rectangle {
                            width: (parent.width - units.gu(1.5)) / 2
                            height: units.gu(8)
                            radius: units.dp(10)
                            color: root.isDarkMode ? "#25262B" : "#F8F9FA"

                            Column {
                                anchors.centerIn: parent
                                spacing: units.gu(0.4)

                                Label {
                                    text: i18n.tr("Goal Date")
                                    font.pixelSize: units.gu(1.2)
                                    color: root.textSecondaryColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Label {
                                    text: settingsPage.selectedDate !== "" ? settingsPage.selectedDate : i18n.tr("Not set")
                                    font.bold: true
                                    font.pixelSize: units.gu(1.6)
                                    color: settingsPage.selectedDate !== "" ? root.primaryColor : root.textSecondaryColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }
                    }
                }

                Column {
                    id: targetsColumn
                    visible: !isViewMode
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

                        TextField {
                            id: kcalInputField
                            placeholderText: i18n.tr("e.g. 500")
                            text: "500"
                            width: parent.width
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            onActiveFocusChanged: {
                                if (activeFocus) ensureVisibleTimer.restart()
                            }
                            onAccepted: {
                                focus = false
                                Qt.inputMethod.hide()
                            }
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

            // ACTION BUTTONS (VIEW MODE vs EDIT MODE)
            Button {
                id: editModeButton
                visible: isViewMode
                text: i18n.tr("Edit Profile & Targets")
                color: root.primaryColor
                width: parent.width
                height: units.gu(5)

                onClicked: {
                    isViewMode = false
                }
            }

            Row {
                id: editActionsRow
                visible: !isViewMode
                width: parent.width
                spacing: units.gu(1.5)

                Button {
                    text: i18n.tr("Cancel")
                    color: root.cardBorderColor
                    width: (parent.width - units.gu(1.5)) / 2
                    height: units.gu(5)

                    onClicked: {
                        loadSettings()
                        isViewMode = true
                    }
                }

                Button {
                    text: i18n.tr("Save Settings")
                    color: root.primaryColor
                    width: (parent.width - units.gu(1.5)) / 2
                    height: units.gu(5)

                    onClicked: saveSettings()
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
            title: i18n.tr("Saved!")

            Column {
                spacing: units.gu(2)
                Label {
                    text: i18n.tr("Your fitness profile have been saved successfully.")
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

    ExportReportModal {
        id: exportModalItem
    }

    Component.onCompleted: {
        loadSettings()
    }
}