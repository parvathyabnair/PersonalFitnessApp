import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import "database.js" as DB

Page {
    id: reminderPage
    anchors.fill: parent

    property var pageLayout
    property int todaysWater: 0
    property int targetWater: 2500

    function loadWaterData() {
        todaysWater = DB.getTodaysWater()
        var s = DB.getSettings()
        if (s && s.target_water) {
            targetWater = parseInt(s.target_water) || 2500
        }
    }

    Component.onCompleted: {
        loadWaterData()
    }

    Connections {
        target: (typeof mainView !== "undefined") ? mainView : ((typeof root !== "undefined") ? root : null)
        onSessionDataChanged: {
            loadWaterData()
        }
    }

    header: PageHeader {
        id: header
        title: i18n.tr("Hydration Reminder")

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
                        pageLayout.removePages(reminderPage)
                    }
                }
            }
        ]
    }

    PropertyAnimation {
        id: scrollAnim
        target: flickable
        property: "contentY"
        duration: 200
        easing.type: Easing.OutQuad
    }

    function ensureVisible(item) {
        if (!item || !flickable) return
        var pos = item.mapToItem(flickable.contentItem, 0, 0)
        var itemY = pos.y
        var itemHeight = item.height
        var viewportHeight = flickable.height
        var margin = units.gu(4)

        var newContentY = flickable.contentY
        if (itemY - margin < flickable.contentY) {
            newContentY = Math.max(0, itemY - margin)
        } else if (itemY + itemHeight + margin > flickable.contentY + viewportHeight) {
            var targetY = itemY + itemHeight + margin - viewportHeight
            var maxY = Math.max(0, flickable.contentHeight - viewportHeight)
            newContentY = Math.min(maxY, targetY)
        }

        if (Math.abs(newContentY - flickable.contentY) > 1) {
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
            if (customMinsField && customMinsField.activeFocus) {
                ensureVisible(customMinsField)
            } else if (customTitleField && customTitleField.activeFocus) {
                ensureVisible(customTitleField)
            }
        }
    }

    Flickable {
        id: flickable
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Qt.inputMethod.visible ? (Qt.inputMethod.keyboardRectangle.height > 0 ? Qt.inputMethod.keyboardRectangle.height : units.gu(30)) : 0
        anchors.left: parent.left
        anchors.right: parent.right
        contentWidth: width
        contentHeight: contentCol.height + units.gu(8)
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
            id: contentCol
            width: parent.width - units.gu(3)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: units.gu(2)
            topPadding: units.gu(2)
            bottomPadding: units.gu(3)

            // STATUS & LIVE COUNTDOWN HERO CARD
            Rectangle {
                width: parent.width
                height: heroCol.height + units.gu(3)
                radius: units.dp(16)
                color: root.cardBgColor
                border.color: (typeof root !== "undefined" && root.reminderActive) ? root.secondaryColor : ((typeof root !== "undefined" && root.reminderPaused) ? "#F59E0B" : root.cardBorderColor)
                border.width: units.dp(1.5)

                Column {
                    id: heroCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: units.gu(1.6)
                    spacing: units.gu(1.4)

                    RowLayout {
                        width: parent.width

                        Row {
                            spacing: units.gu(1)
                            Layout.alignment: Qt.AlignVCenter

                           

                            Column {
                                spacing: units.gu(0.2)

                                Label {
                                    text: i18n.tr("Hydration Timer")
                                    font.bold: true
                                    font.pixelSize: units.gu(1.8)
                                    color: root.textPrimaryColor
                                }

                                Label {
                                    text: (typeof root !== "undefined" && root.reminderActive) ?
                                          (i18n.tr("Repeats every ") + Math.round(root.reminderIntervalSeconds / 60) + i18n.tr(" mins")) :
                                          ((typeof root !== "undefined" && root.reminderPaused) ?
                                           i18n.tr("Timer is currently paused") :
                                           i18n.tr("Reminder is currently inactive"))
                                    font.pixelSize: units.gu(1.1)
                                    color: (typeof root !== "undefined" && root.reminderPaused) ? "#F59E0B" : root.textSecondaryColor
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredHeight: units.gu(2.8)
                            Layout.preferredWidth: Math.max(units.gu(8.5), statusLabel.implicitWidth + units.gu(2.8))
                            implicitHeight: Layout.preferredHeight
                            implicitWidth: Layout.preferredWidth
                            height: Layout.preferredHeight
                            width: Layout.preferredWidth
                            radius: height / 2
                            color: (typeof root !== "undefined" && root.reminderActive && !root.reminderPaused) ? Qt.rgba(16/255, 185/255, 129/255, 0.18) :
                                   ((typeof root !== "undefined" && root.reminderPaused) ? Qt.rgba(245/255, 158/255, 11/255, 0.18) :
                                   (root.isDarkMode ? "#2C2D32" : "#E9ECEF"))
                            border.color: (typeof root !== "undefined" && root.reminderActive && !root.reminderPaused) ? "#10B981" :
                                          ((typeof root !== "undefined" && root.reminderPaused) ? "#F59E0B" : root.cardBorderColor)
                            border.width: units.dp(1.5)

                            Label {
                                id: statusLabel
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: (typeof root !== "undefined" && root.reminderActive && !root.reminderPaused) ? i18n.tr("ACTIVE") :
                                      ((typeof root !== "undefined" && root.reminderPaused) ? i18n.tr("PAUSED") : i18n.tr("OFF"))
                                font.bold: true
                                font.pixelSize: units.gu(1.05)
                                color: (typeof root !== "undefined" && root.reminderActive && !root.reminderPaused) ? "#10B981" :
                                       ((typeof root !== "undefined" && root.reminderPaused) ? "#F59E0B" : root.textSecondaryColor)
                            }
                        }
                    }

                    // Large Countdown Display
                    Rectangle {
                        width: parent.width
                        height: units.gu(9)
                        radius: units.dp(12)
                        color: root.isDarkMode ? "#1B2228" : "#F0F9FF"
                        border.color: (typeof root !== "undefined" && root.reminderActive && !root.reminderPaused) ? root.secondaryColor : ((typeof root !== "undefined" && root.reminderPaused) ? "#F59E0B" : root.cardBorderColor)
                        border.width: units.dp(1)

                        Column {
                            anchors.centerIn: parent
                            spacing: units.gu(0.4)

                            Label {
                                text: (typeof root !== "undefined" && (root.reminderActive || root.reminderPaused)) ?
                                      (Math.floor(root.reminderSecondsLeft / 60) + "m " + (root.reminderSecondsLeft % 60 < 10 ? "0" : "") + (root.reminderSecondsLeft % 60) + "s") :
                                      "--:--"
                                font.bold: true
                                font.pixelSize: units.gu(3.2)
                                color: (typeof root !== "undefined" && root.reminderActive && !root.reminderPaused) ? root.secondaryColor :
                                       ((typeof root !== "undefined" && root.reminderPaused) ? "#F59E0B" : root.textSecondaryColor)
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Label {
                                text: (typeof root !== "undefined" && root.reminderActive && !root.reminderPaused) ?
                                      i18n.tr("Time remaining until next water notification") :
                                      ((typeof root !== "undefined" && root.reminderPaused) ?
                                       i18n.tr("Timer paused • Tap Resume to continue") :
                                       i18n.tr("Select an interval below to start timer"))
                                font.pixelSize: units.gu(1.1)
                                color: root.textSecondaryColor
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    // Primary Action Controls (Pause, Resume, Stop, Start)
                    Row {
                        width: parent.width
                        spacing: units.gu(1.2)

                        // When Active: Pause and Stop
                        Button {
                            visible: (typeof root !== "undefined" && root.reminderActive && !root.reminderPaused)
                            width: (parent.width - units.gu(1.2)) / 2
                            height: units.gu(4.8)
                            text: i18n.tr("Pause")
                            color: "#F59E0B"
                            onClicked: {
                                if (typeof root !== "undefined") root.pauseReminder()
                            }
                        }

                        Button {
                            visible: (typeof root !== "undefined" && root.reminderActive && !root.reminderPaused)
                            width: (parent.width - units.gu(1.2)) / 2
                            height: units.gu(4.8)
                            text: i18n.tr("Stop")
                            color: "#EF4444"
                            onClicked: {
                                if (typeof root !== "undefined") root.stopReminder()
                            }
                        }

                        // When Paused: Resume and Stop
                        Button {
                            visible: (typeof root !== "undefined" && root.reminderPaused && !root.reminderActive)
                            width: (parent.width - units.gu(1.2)) / 2
                            height: units.gu(4.8)
                            text: i18n.tr("Resume")
                            color: "#10B981"
                            onClicked: {
                                if (typeof root !== "undefined") root.resumeReminder()
                            }
                        }

                        Button {
                            visible: (typeof root !== "undefined" && root.reminderPaused && !root.reminderActive)
                            width: (parent.width - units.gu(1.2)) / 2
                            height: units.gu(4.8)
                            text: i18n.tr("Stop")
                            color: "#EF4444"
                            onClicked: {
                                if (typeof root !== "undefined") root.stopReminder()
                            }
                        }

                        // When Off: Start Reminder
                        Button {
                            visible: (typeof root !== "undefined" && !root.reminderActive && !root.reminderPaused)
                            width: parent.width
                            height: units.gu(4.8)
                            text: i18n.tr("Start Reminder")
                            color: root.secondaryColor
                            onClicked: {
                                if (typeof root !== "undefined") {
                                    var m = parseInt(customMinsField.text.trim()) || 45
                                    var t = customTitleField.text.trim() || i18n.tr("Time to Hydrate!")
                                    root.startReminder(
                                        m * 60,
                                        t,
                                        i18n.tr("Take a refreshing drink of water to keep your hydration on track."),
                                        repeatCheck.checked,
                                        "water"
                                    )
                                }
                            }
                        }
                    }
                }
            }

            // INTERVAL & CONFIGURATION CARD
            Rectangle {
                width: parent.width
                height: configCol.height + units.gu(3)
                radius: units.dp(16)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)

                Column {
                    id: configCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: units.gu(1.6)
                    spacing: units.gu(1.5)

                    Label {
                        text: i18n.tr("Reminder Settings")
                        font.bold: true
                        font.pixelSize: units.gu(1.6)
                        color: root.textPrimaryColor
                    }

                    // Preset Interval Chips
                    Column {
                        width: parent.width
                        spacing: units.gu(0.6)

                        Label {
                            text: i18n.tr("Quick Interval Presets")
                            font.bold: true
                            font.pixelSize: units.gu(1.3)
                            color: root.textSecondaryColor
                        }

                        Row {
                            width: parent.width
                            spacing: units.gu(0.8)

                            Repeater {
                                model: ["15", "30", "45", "60", "90", "120"]

                                Rectangle {
                                    property bool isSelected: customMinsField.text === modelData
                                    width: (parent.width - units.gu(4)) / 6
                                    height: units.gu(3.8)
                                    radius: units.dp(8)
                                    color: isSelected ? root.secondaryColor : (root.isDarkMode ? "#2C2D32" : "#F1F3F5")
                                    border.color: isSelected ? root.secondaryColor : root.cardBorderColor
                                    border.width: units.dp(1)

                                    Label {
                                        anchors.centerIn: parent
                                        text: modelData + "m"
                                        font.bold: isSelected
                                        font.pixelSize: units.gu(1.2)
                                        color: isSelected ? "#1A1B1E" : root.textPrimaryColor
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            customMinsField.text = modelData
                                            if (typeof root !== "undefined" && (root.reminderActive || root.reminderPaused)) {
                                                root.startReminder(
                                                    parseInt(modelData) * 60,
                                                    customTitleField.text.trim() || i18n.tr("Time to Hydrate!"),
                                                    i18n.tr("Take a refreshing drink of water to keep your hydration on track."),
                                                    repeatCheck.checked,
                                                    "water"
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Custom Interval in Minutes
                    Column {
                        width: parent.width
                        spacing: units.gu(0.6)

                        Label {
                            text: i18n.tr("Custom Minutes")
                            font.bold: true
                            font.pixelSize: units.gu(1.3)
                            color: root.textSecondaryColor
                        }

                        TextField {
                            id: customMinsField
                            text: (typeof root !== "undefined" && root.reminderIntervalSeconds > 0) ? String(Math.round(root.reminderIntervalSeconds / 60)) : "45"
                            placeholderText: "45"
                            width: parent.width
                            inputMethodHints: Qt.ImhDigitsOnly
                            onActiveFocusChanged: {
                                if (activeFocus) ensureVisibleTimer.restart()
                            }
                            onAccepted: {
                                focus = false
                                Qt.inputMethod.hide()
                                var m = parseInt(text.trim()) || 45
                                if (typeof root !== "undefined" && (root.reminderActive || root.reminderPaused)) {
                                    root.startReminder(
                                        m * 60,
                                        customTitleField.text.trim() || i18n.tr("Time to Hydrate!"),
                                        i18n.tr("Take a refreshing drink of water to keep your hydration on track."),
                                        repeatCheck.checked,
                                        "water"
                                    )
                                }
                            }
                        }
                    }

                    // Reminder Title
                    Column {
                        width: parent.width
                        spacing: units.gu(0.6)

                        Label {
                            text: i18n.tr("Reminder Label")
                            font.bold: true
                            font.pixelSize: units.gu(1.3)
                            color: root.textSecondaryColor
                        }

                        TextField {
                            id: customTitleField
                            text: (typeof root !== "undefined" && root.reminderTitle) ? root.reminderTitle : i18n.tr("💧 Time to Hydrate!")
                            placeholderText: i18n.tr("e.g. 💧 Time to Hydrate!")
                            width: parent.width
                            onActiveFocusChanged: {
                                if (activeFocus) ensureVisibleTimer.restart()
                            }
                            onAccepted: {
                                focus = false
                                Qt.inputMethod.hide()
                            }
                        }
                    }

                    // Repeat Option
                    RowLayout {
                        width: parent.width

                        Label {
                            text: i18n.tr("Repeat reminder every interval")
                            font.pixelSize: units.gu(1.3)
                            color: root.textPrimaryColor
                        }

                        Item { Layout.fillWidth: true }

                        CheckBox {
                            id: repeatCheck
                            checked: (typeof root !== "undefined") ? root.reminderRepeat : true
                            onCheckedChanged: {
                                if (typeof root !== "undefined") {
                                    root.reminderRepeat = checked
                                }
                            }
                        }
                    }
                }
            }

            // TODAY'S HYDRATION QUICK LOG CARD
            Rectangle {
                width: parent.width
                height: logCol.height + units.gu(3)
                radius: units.dp(16)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)

                Column {
                    id: logCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: units.gu(1.6)
                    spacing: units.gu(1.4)

                    RowLayout {
                        width: parent.width

                        Label {
                            text: i18n.tr("Today's Hydration Progress")
                            font.bold: true
                            font.pixelSize: units.gu(1.5)
                            color: root.textPrimaryColor
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            text: todaysWater + " / " + targetWater + " ml"
                            font.bold: true
                            font.pixelSize: units.gu(1.4)
                            color: root.secondaryColor
                        }
                    }

                    // Progress bar
                    Rectangle {
                        width: parent.width
                        height: units.gu(1.4)
                        radius: height / 2
                        color: root.isDarkMode ? "#373A40" : "#E9ECEF"

                        Rectangle {
                            width: Math.min(parent.width, Math.max(units.gu(1.4), parent.width * Math.min(1.0, todaysWater / targetWater)))
                            height: parent.height
                            radius: parent.radius
                            color: root.secondaryColor

                            Behavior on width {
                                NumberAnimation { duration: 400; easing.type: Easing.OutQuad }
                            }
                        }
                    }

                    // Quick Log Buttons
                    Row {
                        width: parent.width
                        spacing: units.gu(1)

                        Button {
                            width: (parent.width - units.gu(2)) / 3
                            height: units.gu(4)
                            text: i18n.tr("+250 ml (Cup)")
                            color: root.secondaryColor
                            onClicked: {
                                todaysWater = DB.addWater(250)
                                if (typeof root !== "undefined") root.sessionDataChanged()
                            }
                        }

                        Button {
                            width: (parent.width - units.gu(2)) / 3
                            height: units.gu(4)
                            text: i18n.tr("+500 ml")
                            color: root.secondaryColor
                            onClicked: {
                                todaysWater = DB.addWater(500)
                                if (typeof root !== "undefined") root.sessionDataChanged()
                            }
                        }

                        Button {
                            width: (parent.width - units.gu(2)) / 3
                            height: units.gu(4)
                            text: i18n.tr("Reset")
                            color: root.cardBorderColor
                            onClicked: {
                                todaysWater = DB.resetTodaysWater()
                                if (typeof root !== "undefined") root.sessionDataChanged()
                            }
                        }
                    }
                }
            }
        }
    }
}
