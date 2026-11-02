import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import "components"
import "database.js" as DB

Page {
    id: homePage
    anchors.fill: parent
    property var pageLayout
    property string currentWeight: "0"
    property string todaysCalories: "0"
    property string goalWeight: "0"
    property real targetCalories: 500
    property real progressPercentage: 0
    property var weeklyData: []

    property int todaysWater: 0
    property int targetWater: 2500
    property var workoutStats: ({ totalWorkouts: 0, streakDays: 0, thisMonthWorkouts: 0, thisMonthDurationSeconds: 0, thisWeekWorkouts: 0, totalDurationSeconds: 0, totalCalories: 0 })
    property int selectedHydrationMins: (typeof root !== "undefined" && root.reminderIntervalSeconds > 0) ? Math.round(root.reminderIntervalSeconds / 60) : 45

    function loadOverviewData() {
        var settings = DB.getSettings()
        if (settings) {
            currentWeight = settings.weight ? settings.weight : "0"
            goalWeight = settings.goal_weight ? settings.goal_weight : "0"
            targetCalories = parseFloat(settings.kcal_target) || 500
        }
        var cal = DB.getTodaysCalories()
        todaysCalories = Math.round(cal).toString()
        var pct = targetCalories > 0 ? (cal / targetCalories) * 100 : 0
        if (pct > 100) pct = 100
        progressPercentage = Math.round(pct)
        
        var wData = DB.getWeeklyCalories()
        var formattedData = [];
        for (var i = 0; i < wData.length; i++) {
            formattedData.push({label: wData[i].dateLabel, value: wData[i].calories});
        }
        weeklyData = formattedData;
        if (typeof chartCanvas !== "undefined" && chartCanvas.requestPaint) {
            chartCanvas.requestPaint();
        }

        todaysWater = DB.getTodaysWater();
        workoutStats = DB.getWorkoutStats();
    }

    Component.onCompleted: {
        loadOverviewData()
    }

    Connections {
        target: (typeof mainView !== "undefined") ? mainView : ((typeof root !== "undefined") ? root : null)
        onSessionDataChanged: {
            loadOverviewData()
        }
    }

    onVisibleChanged: {
        if (visible) {
            loadOverviewData()
        }
    }

    header: PageHeader {
        id: header
        title: i18n.tr("Personal Fitness")

        StyleHints {
            foregroundColor: "white"
            backgroundColor: root.primaryColor
            dividerColor: LomiriColors.slate
        }

        trailingActionBar.numberOfSlots: 2

        trailingActionBar.actions: [
            Action {
                iconName: theme.name === "Ubuntu.Components.Themes.SuruDark" ?
                          "weather-clear-symbolic" :
                          "weather-clear-night-symbolic"

                text: theme.name === "Ubuntu.Components.Themes.SuruDark" ?
                      i18n.tr("Light Mode") : i18n.tr("Dark Mode")

                onTriggered: {
                    var newTheme =
                        theme.name === "Ubuntu.Components.Themes.SuruDark" ?
                        "Ubuntu.Components.Themes.Ambiance" :
                        "Ubuntu.Components.Themes.SuruDark"

                    Theme.name = newTheme
                    if (typeof chartCanvas !== "undefined" && chartCanvas.requestPaint) {
                        chartCanvas.requestPaint();
                    }
                }
            },

            Action {
                iconName: "media-playback-start"
                text: i18n.tr("Active Session")

                onTriggered: {
                    pageLayout.addPageToNextColumn(homePage, Qt.resolvedUrl("ActiveSessionPage.qml"), {pageLayout: pageLayout})
                }
            },

            Action {
                iconName: "view-list-symbolic"
                iconSource: (theme.name === "Ubuntu.Components.Themes.SuruDark" || root.isDarkMode) ?
                            Qt.resolvedUrl("../assets/eye_white.svg") :
                            Qt.resolvedUrl("../assets/eye_dark.svg")
                text: i18n.tr("Session Overview")

                onTriggered: {
                    pageLayout.addPageToNextColumn(homePage, Qt.resolvedUrl("AddSessionPage.qml"), {pageLayout: pageLayout})
                }
            },

            Action {
                iconName: "alarm-clock"
                text: i18n.tr("Hydration Reminder")

                onTriggered: {
                    pageLayout.addPageToNextColumn(homePage, Qt.resolvedUrl("HydrationReminderPage.qml"), {pageLayout: pageLayout})
                }
            },

            Action {
                iconName: "settings"
                text: i18n.tr("Settings")

                onTriggered: {
                    pageLayout.addPageToNextColumn(homePage, Qt.resolvedUrl("SettingsPage.qml"), {pageLayout: pageLayout})
                }
            },

            Action {
                iconName: "document-save-as"
                text: i18n.tr("Export Report")

                onTriggered: {
                    exportModalItem.openModal()
                }
            },

            Action {
                iconName: "camera-app"
                iconSource: (theme.name === "Ubuntu.Components.Themes.SuruDark" || root.isDarkMode) ?
                            Qt.resolvedUrl("../assets/camera_white.svg") :
                            Qt.resolvedUrl("../assets/camera_dark.svg")
                text: i18n.tr("Private Media Vault")

                onTriggered: {
                    pageLayout.addPageToNextColumn(homePage, Qt.resolvedUrl("MediaVaultPage.qml"), {pageLayout: pageLayout})
                }
            },

            Action {
                iconName: "help"
                text: i18n.tr("MET Sports Guide")

                onTriggered: {
                    metGuideModal.visible = true
                }
            }
        ]
    }

    // Scrollable Main Content to prevent any overflow on mobile
    Flickable {
        id: mainFlickable
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        contentWidth: width
        contentHeight: contentColumn.height + units.gu(8)
        clip: true
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.DragOverBounds

        Column {
            id: contentColumn
            width: parent.width - units.gu(3)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: units.gu(2)
            topPadding: units.gu(2)
            bottomPadding: units.gu(2)

            // GREETING & DATE BANNER
            RowLayout {
                width: parent.width

                Column {
                    Layout.fillWidth: true
                    spacing: units.gu(0.3)

                    Row {
                        spacing: units.gu(1)

                        Label {
                            text: i18n.tr("Welcome Back!")
                            font.pixelSize: units.gu(2.4)
                            font.bold: true
                            color: root.textPrimaryColor
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Image {
                            source: Qt.resolvedUrl("../assets/muscle-svgrepo-com.svg")
                            width: units.gu(2.8)
                            height: units.gu(2.8)
                            sourceSize.width: units.gu(2.8)
                            sourceSize.height: units.gu(2.8)
                            anchors.verticalCenter: parent.verticalCenter
                            fillMode: Image.PreserveAspectFit
                        }
                    }

                    Label {
                        text: Qt.formatDate(new Date(), "dddd, d MMMM yyyy")
                        font.pixelSize: units.gu(1.4)
                        color: root.textSecondaryColor
                    }
                }

                // Active Workout Quick Indicator if session is live
                Rectangle {
                    visible: root.activeSessionRunning
                    height: units.gu(3.5)
                    width: activeSessionLabel.width + units.gu(3)
                    radius: height / 2
                    color: root.primaryColor

                    Row {
                        anchors.centerIn: parent
                        spacing: units.gu(0.8)

                        Rectangle {
                            width: units.gu(1)
                            height: units.gu(1)
                            radius: width / 2
                            color: "white"
                            anchors.verticalCenter: parent.verticalCenter

                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 0.2; duration: 600 }
                                NumberAnimation { from: 0.2; to: 1.0; duration: 600 }
                            }
                        }

                        Label {
                            id: activeSessionLabel
                            text: i18n.tr("Live Session")
                            font.bold: true
                            font.pixelSize: units.gu(1.3)
                            color: "white"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            pageLayout.addPageToNextColumn(pageLayout.primaryPage, Qt.resolvedUrl("ActiveSessionPage.qml"), {pageLayout: pageLayout})
                        }
                    }
                }
            }


            // HERO METRIC CARDS ROW
            Row {
                id: cardsRow
                width: parent.width
                spacing: units.gu(1.2)

                // Today's Calories Card
                Rectangle {
                    width: (parent.width - units.gu(2.4)) / 3
                    height: units.gu(11)
                    radius: units.dp(12)
                    color: root.cardBgColor
                    border.color: root.cardBorderColor
                    border.width: units.dp(1)

                    Rectangle {
                        width: parent.width
                        height: units.dp(4)
                        anchors.top: parent.top
                        radius: units.dp(12)
                        color: root.primaryColor
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: units.gu(0.4)
                        width: parent.width - units.gu(1)

                        Image {
                            source: Qt.resolvedUrl("../assets/fire-svgrepo-com.svg")
                            width: units.gu(2.5)
                            height: units.gu(2.5)
                            sourceSize.width: units.gu(2.5)
                            sourceSize.height: units.gu(2.5)
                            fillMode: Image.PreserveAspectFit
                            anchors.horizontalCenter: parent.horizontalCenter
                        }   
                        

                        Label {
                            text: todaysCalories
                            font.pixelSize: units.gu(2.4)
                            font.bold: true
                            color: root.textPrimaryColor
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Label {
                            text: i18n.tr("Calories (kcal)")
                            font.pixelSize: units.gu(1.1)
                            color: root.textSecondaryColor
                            anchors.horizontalCenter: parent.horizontalCenter
                            elide: Text.ElideRight
                        }
                    }
                }

                // Current Weight Card
                Rectangle {
                    width: (parent.width - units.gu(2.4)) / 3
                    height: units.gu(11)
                    radius: units.dp(12)
                    color: root.cardBgColor
                    border.color: root.cardBorderColor
                    border.width: units.dp(1)

                    Rectangle {
                        width: parent.width
                        height: units.dp(4)
                        anchors.top: parent.top
                        radius: units.dp(12)
                        color: root.secondaryColor
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: units.gu(0.4)
                        width: parent.width - units.gu(1)

                        Image {
                            source: Qt.resolvedUrl("../assets/balance-scale-svgrepo-com.svg")
                            width: units.gu(2.5)
                            height: units.gu(2.5)
                            sourceSize.width: units.gu(2.5)
                            sourceSize.height: units.gu(2.5)
                            fillMode: Image.PreserveAspectFit
                            anchors.horizontalCenter: parent.horizontalCenter
                        }   

                        Label {
                            text: currentWeight + " kg"
                            font.pixelSize: units.gu(2.4)
                            font.bold: true
                            color: root.textPrimaryColor
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Label {
                            text: i18n.tr("Current Weight")
                            font.pixelSize: units.gu(1.1)
                            color: root.textSecondaryColor
                            anchors.horizontalCenter: parent.horizontalCenter
                            elide: Text.ElideRight
                        }
                    }
                }

                // Goal Weight Card
                Rectangle {
                    width: (parent.width - units.gu(2.4)) / 3
                    height: units.gu(11)
                    radius: units.dp(12)
                    color: root.cardBgColor
                    border.color: root.cardBorderColor
                    border.width: units.dp(1)

                    Rectangle {
                        width: parent.width
                        height: units.dp(4)
                        anchors.top: parent.top
                        radius: units.dp(12)
                        color: root.accentGreen
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: units.gu(0.4)
                        width: parent.width - units.gu(1)

                        Image {
                            source: Qt.resolvedUrl("../assets/target-svgrepo-com.svg")
                            width: units.gu(2.5)
                            height: units.gu(2.5)
                            sourceSize.width: units.gu(2.5)
                            sourceSize.height: units.gu(2.5)
                            fillMode: Image.PreserveAspectFit
                            anchors.horizontalCenter: parent.horizontalCenter
                        }   

                        Label {
                            text: goalWeight + " kg"
                            font.pixelSize: units.gu(2.4)
                            font.bold: true
                            color: root.textPrimaryColor
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Label {
                            text: i18n.tr("Goal Target")
                            font.pixelSize: units.gu(1.1)
                            color: root.textSecondaryColor
                            anchors.horizontalCenter: parent.horizontalCenter
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            // DAILY CALORIE GOAL PROGRESS CARD
            Rectangle {
                width: parent.width
                height: units.gu(9.5)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)

                Column {
                    anchors.fill: parent
                    anchors.margins: units.gu(1.5)
                    spacing: units.gu(1)

                    RowLayout {
                        width: parent.width

                        Label {
                            text: i18n.tr("Daily Calorie Target")
                            font.bold: true
                            font.pixelSize: units.gu(1.6)
                            color: root.textPrimaryColor
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            text: todaysCalories + " / " + Math.round(targetCalories) + " kcal (" + progressPercentage + "%)"
                            font.bold: true
                            font.pixelSize: units.gu(1.4)
                            color: root.primaryColor
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: units.gu(1.4)
                        radius: height / 2
                        color: root.isDarkMode ? "#373A40" : "#E9ECEF"

                        Rectangle {
                            width: Math.min(parent.width, Math.max(units.gu(1.4), parent.width * (progressPercentage / 100)))
                            height: parent.height
                            radius: parent.radius
                            color: root.primaryColor

                            Behavior on width {
                                NumberAnimation { duration: 600; easing.type: Easing.OutQuad }
                            }
                        }
                    }
                }
            }

            // ACTIVITY SUMMARY - THIS MONTH
            Rectangle {
                width: parent.width
                height: streakCol.height + units.gu(2.8)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)

                Column {
                    id: streakCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: units.gu(1.4)
                    spacing: units.gu(1.2)

                    RowLayout {
                        width: parent.width

                        Row {
                            spacing: units.gu(0.8)

                            Label {
                                text: i18n.tr("Activity Summary")
                                font.bold: true
                                font.pixelSize: units.gu(1.6)
                                color: root.textPrimaryColor
                            }
                        }

                        Item { Layout.fillWidth: true }

                        AbstractButton {
                            height: units.gu(3.6)
                            width: contentRow.implicitWidth + units.gu(2)
                            onClicked: exportModalItem.openModal()

                            Rectangle {
                                anchors.fill: parent
                                radius: units.dp(8)
                                color: Qt.rgba(root.secondaryColor.r, root.secondaryColor.g, root.secondaryColor.b, 0.15)
                                border.color: root.secondaryColor
                                border.width: units.dp(1)

                                Row {
                                    id: contentRow
                                    anchors.centerIn: parent
                                    spacing: units.gu(0.6)

                                    Icon {
                                        name: "document-save-as"
                                        width: units.gu(1.8)
                                        height: units.gu(1.8)
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: root.isDarkMode ? root.secondaryColor : Qt.darker(root.secondaryColor, 1.25)
                                    }

                                    Label {
                                        text: i18n.tr("Export Report")
                                        font.bold: true
                                        font.pixelSize: units.gu(1.15)
                                        color: root.isDarkMode ? root.secondaryColor : Qt.darker(root.secondaryColor, 1.25)
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }

                    }

                    // Stats Triplet Row: Workouts (This Month), This Week, Total Training Time
                    Row {
                        width: parent.width
                        spacing: units.gu(1)

                        // Box 1: This Month Workouts
                        Rectangle {
                            width: (parent.width - units.gu(2)) / 3
                            height: units.gu(6.6)
                            radius: units.dp(8)
                            color: root.isDarkMode ? "#25262B" : "#F8F9FA"

                            Column {
                                anchors.centerIn: parent
                                spacing: units.gu(0.2)

                                Label {
                                    text: workoutStats.thisMonthWorkouts
                                    font.bold: true
                                    font.pixelSize: units.gu(2.0)
                                    color: root.primaryColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Label {
                                    text: i18n.tr("This Month")
                                    font.pixelSize: units.gu(0.95)
                                    color: root.textSecondaryColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }

                        // Box 2: This Week Workouts
                        Rectangle {
                            width: (parent.width - units.gu(2)) / 3
                            height: units.gu(6.6)
                            radius: units.dp(8)
                            color: root.isDarkMode ? "#25262B" : "#F8F9FA"

                            Column {
                                anchors.centerIn: parent
                                spacing: units.gu(0.2)

                                Label {
                                    text: workoutStats.thisWeekWorkouts
                                    font.bold: true
                                    font.pixelSize: units.gu(2.0)
                                    color: root.secondaryColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Label {
                                    text: i18n.tr("This Week")
                                    font.pixelSize: units.gu(0.95)
                                    color: root.textSecondaryColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }

                        // Box 3: Month Training Time
                        Rectangle {
                            width: (parent.width - units.gu(2)) / 3
                            height: units.gu(6.6)
                            radius: units.dp(8)
                            color: root.isDarkMode ? "#25262B" : "#F8F9FA"

                            Column {
                                anchors.centerIn: parent
                                spacing: units.gu(0.2)

                                Label {
                                    text: {
                                        var secs = workoutStats.thisMonthDurationSeconds || 0
                                        if (secs > 0 && secs < 3600) {
                                            return Math.round(secs / 60) + "m"
                                        }
                                        return (secs / 3600).toFixed(1) + "h"
                                    }
                                    font.bold: true
                                    font.pixelSize: units.gu(2.0)
                                    color: root.accentGreen
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Label {
                                    text: {
                                        var secs = workoutStats.thisMonthDurationSeconds || 0
                                        return (secs > 0 && secs < 3600) ? i18n.tr("Month Time") : i18n.tr("Month Hours")
                                    }
                                    font.pixelSize: units.gu(0.95)
                                    color: root.textSecondaryColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }
                    }
                }
            }

            // DAILY HYDRATION TRACKER CARD
            Rectangle {
                id: hydrationCard
                property string selectedHydrationAction: ""
                width: parent.width
                height: waterCol.height + units.gu(2.8)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)

                Column {
                    id: waterCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: units.gu(1.4)
                    spacing: units.gu(1.2)

                    RowLayout {
                        width: parent.width

                        Row {
                            spacing: units.gu(0.8)
                            Layout.alignment: Qt.AlignVCenter

                           
                            Label {
                                text: i18n.tr("Hydration Tracker")
                                font.bold: true
                                font.pixelSize: units.gu(1.6)
                                color: root.textPrimaryColor
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            text: todaysWater + " / " + targetWater + " ml (" + Math.min(100, Math.round((todaysWater / targetWater) * 100)) + "%)"
                            font.bold: true
                            font.pixelSize: units.gu(1.3)
                            color: root.secondaryColor
                        }
                    }

                    // Water progress bar
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

                        // +250 ml (Cup)
                        Rectangle {
                            width: (parent.width - units.gu(2)) / 3
                            height: units.gu(3.8)
                            radius: units.dp(8)
                            color: (hydrationCard.selectedHydrationAction === "cup" || cupMouse.pressed) ? root.secondaryColor : (root.isDarkMode ? "#25262B" : "#F1F3F5")
                            border.color: (hydrationCard.selectedHydrationAction === "cup" || cupMouse.pressed) ? root.secondaryColor : root.cardBorderColor
                            border.width: units.dp(1)

                            Label {
                                anchors.centerIn: parent
                                text: i18n.tr("+250 ml (Cup)")
                                font.bold: hydrationCard.selectedHydrationAction === "cup" || cupMouse.pressed
                                font.pixelSize: units.gu(1.1)
                                color: (hydrationCard.selectedHydrationAction === "cup" || cupMouse.pressed) ? "#1A1B1E" : root.textPrimaryColor
                            }

                            MouseArea {
                                id: cupMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    hydrationCard.selectedHydrationAction = "cup"
                                    todaysWater = DB.addWater(250)
                                }
                            }
                        }

                        // +500 ml (Bottle)
                        Rectangle {
                            width: (parent.width - units.gu(2)) / 3
                            height: units.gu(3.8)
                            radius: units.dp(8)
                            color: (hydrationCard.selectedHydrationAction === "bottle" || bottleMouse.pressed) ? root.secondaryColor : (root.isDarkMode ? "#25262B" : "#F1F3F5")
                            border.color: (hydrationCard.selectedHydrationAction === "bottle" || bottleMouse.pressed) ? root.secondaryColor : root.cardBorderColor
                            border.width: units.dp(1)

                            Label {
                                anchors.centerIn: parent
                                text: i18n.tr("+500 ml (Bottle)")
                                font.bold: hydrationCard.selectedHydrationAction === "bottle" || bottleMouse.pressed
                                font.pixelSize: units.gu(1.1)
                                color: (hydrationCard.selectedHydrationAction === "bottle" || bottleMouse.pressed) ? "#1A1B1E" : root.textPrimaryColor
                            }

                            MouseArea {
                                id: bottleMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    hydrationCard.selectedHydrationAction = "bottle"
                                    todaysWater = DB.addWater(500)
                                }
                            }
                        }

                        // Reset
                        Rectangle {
                            width: (parent.width - units.gu(2)) / 3
                            height: units.gu(3.8)
                            radius: units.dp(8)
                            color: (hydrationCard.selectedHydrationAction === "reset" || resetMouse.pressed) ? root.secondaryColor : (root.isDarkMode ? "#25262B" : "#F1F3F5")
                            border.color: (hydrationCard.selectedHydrationAction === "reset" || resetMouse.pressed) ? root.secondaryColor : root.cardBorderColor
                            border.width: units.dp(1)

                            Label {
                                anchors.centerIn: parent
                                text: i18n.tr("Reset")
                                font.bold: hydrationCard.selectedHydrationAction === "reset" || resetMouse.pressed
                                font.pixelSize: units.gu(1.1)
                                color: (hydrationCard.selectedHydrationAction === "reset" || resetMouse.pressed) ? "#1A1B1E" : root.textPrimaryColor
                            }

                            MouseArea {
                                id: resetMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    hydrationCard.selectedHydrationAction = "reset"
                                    todaysWater = DB.resetTodaysWater()
                                }
                            }
                        }
                    }
                }
            }

            // HYDRATION REMINDER DASHBOARD MENU CARD
            Rectangle {
                width: parent.width
                height: reminderDashboardCol.height + units.gu(3)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: (typeof root !== "undefined" && root.reminderActive) ? root.secondaryColor : ((typeof root !== "undefined" && root.reminderPaused) ? "#F59E0B" : root.cardBorderColor)
                border.width: units.dp(1)

                Column {
                    id: reminderDashboardCol
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

                          

                            Column {
                                spacing: units.gu(0.1)

                                Label {
                                    text: i18n.tr("Hydration Reminder")
                                    font.bold: true
                                    font.pixelSize: units.gu(1.6)
                                    color: root.textPrimaryColor
                                }

                                Label {
                                    text: (typeof root !== "undefined" && root.reminderActive) ?
                                          (i18n.tr("Next drink in ") + Math.floor(root.reminderSecondsLeft / 60) + "m " + (root.reminderSecondsLeft % 60 < 10 ? "0" : "") + (root.reminderSecondsLeft % 60) + "s") :
                                          ((typeof root !== "undefined" && root.reminderPaused) ?
                                           (i18n.tr("Paused • ") + Math.floor(root.reminderSecondsLeft / 60) + "m " + (root.reminderSecondsLeft % 60 < 10 ? "0" : "") + (root.reminderSecondsLeft % 60) + "s remaining") :
                                           (i18n.tr("Reminder is off • Interval: ") + homePage.selectedHydrationMins + i18n.tr("m")))
                                    font.pixelSize: units.gu(1.1)
                                    font.bold: (typeof root !== "undefined" && (root.reminderActive || root.reminderPaused))
                                    color: (typeof root !== "undefined" && root.reminderActive) ? root.secondaryColor : ((typeof root !== "undefined" && root.reminderPaused) ? "#F59E0B" : root.textSecondaryColor)
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredHeight: units.gu(2.8)
                            Layout.preferredWidth: Math.max(units.gu(8.5), homeReminderStatusLabel.implicitWidth + units.gu(2.8))
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
                                id: homeReminderStatusLabel
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

                    // Quick Preset Chips
                    Row {
                        width: parent.width
                        spacing: units.gu(0.8)

                        Repeater {
                            model: [
                                { label: "30m", mins: 30 },
                                { label: "45m", mins: 45 },
                                { label: "60m", mins: 60 },
                                { label: "90m", mins: 90 },
                                { label: "120m", mins: 120 }
                            ]

                            Rectangle {
                                property bool isSelected: (typeof root !== "undefined" && (root.reminderActive || root.reminderPaused)) ?
                                    (Math.round(root.reminderIntervalSeconds / 60) === modelData.mins) :
                                    (homePage.selectedHydrationMins === modelData.mins)
                                width: (parent.width - units.gu(3.2)) / 5
                                height: units.gu(3.4)
                                radius: units.dp(6)
                                color: isSelected ? root.secondaryColor : (root.isDarkMode ? "#2C2D32" : "#F1F3F5")
                                border.color: isSelected ? root.secondaryColor : root.cardBorderColor
                                border.width: units.dp(1)

                                Label {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.bold: isSelected
                                    font.pixelSize: units.gu(1.1)
                                    color: isSelected ? "#1A1B1E" : root.textPrimaryColor
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        homePage.selectedHydrationMins = modelData.mins
                                        if (typeof root !== "undefined" && (root.reminderActive || root.reminderPaused)) {
                                            root.startReminder(
                                                modelData.mins * 60,
                                                i18n.tr("Time to Hydrate!"),
                                                i18n.tr("Drink a glass of water to keep your metabolism and hydration at peak performance."),
                                                true,
                                                "water"
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Quick Action Row
                    Row {
                        width: parent.width
                        spacing: units.gu(1)

                        // When Active: Pause and Stop
                        Button {
                            visible: (typeof root !== "undefined" && root.reminderActive && !root.reminderPaused)
                            text: i18n.tr("Pause")
                            color: "#F59E0B"
                            width: (parent.width - units.gu(1)) / 2
                            height: units.gu(3.8)
                            onClicked: {
                                if (typeof root !== "undefined") root.pauseReminder()
                            }
                        }

                        Button {
                            visible: (typeof root !== "undefined" && root.reminderActive && !root.reminderPaused)
                            text: i18n.tr("Stop")
                            color: "#EF4444"
                            width: (parent.width - units.gu(1)) / 2
                            height: units.gu(3.8)
                            onClicked: {
                                if (typeof root !== "undefined") root.stopReminder()
                            }
                        }

                        // When Paused: Resume and Stop
                        Button {
                            visible: (typeof root !== "undefined" && root.reminderPaused && !root.reminderActive)
                            text: i18n.tr("Resume")
                            color: "#10B981"
                            width: (parent.width - units.gu(1)) / 2
                            height: units.gu(3.8)
                            onClicked: {
                                if (typeof root !== "undefined") root.resumeReminder()
                            }
                        }

                        Button {
                            visible: (typeof root !== "undefined" && root.reminderPaused && !root.reminderActive)
                            text: i18n.tr("Stop")
                            color: "#EF4444"
                            width: (parent.width - units.gu(1)) / 2
                            height: units.gu(3.8)
                            onClicked: {
                                if (typeof root !== "undefined") root.stopReminder()
                            }
                        }

                        // When Off: Start Reminder with selected duration
                        Button {
                            visible: (typeof root !== "undefined" && !root.reminderActive && !root.reminderPaused)
                            text: i18n.tr("Start Reminder (") + homePage.selectedHydrationMins + i18n.tr("m)")
                            color: root.secondaryColor
                            width: parent.width
                            height: units.gu(3.8)
                            onClicked: {
                                if (typeof root !== "undefined") {
                                    root.startReminder(
                                        homePage.selectedHydrationMins * 60,
                                        i18n.tr("Time to Hydrate!"),
                                        i18n.tr("Drink a glass of water to keep your metabolism and hydration at peak performance."),
                                        true,
                                        "water"
                                    )
                                }
                            }
                        }
                    }
                }
            }

            // WEEKLY PROGRESS CHART CARD
            Rectangle {
                id: weeklyChartRect
                width: parent.width
                height: units.gu(26)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)

                Column {
                    anchors.fill: parent
                    anchors.margins: units.gu(1.5)
                    spacing: units.gu(1)

                    RowLayout {
                        width: parent.width

                        Label {
                            text: i18n.tr("Weekly Progress")
                            color: root.textPrimaryColor
                            font.bold: true
                            font.pixelSize: units.gu(1.8)
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            text: i18n.tr("Calories (kcal)")
                            color: root.textSecondaryColor
                            font.pixelSize: units.gu(1.2)
                        }
                    }

                    Canvas {
                        id: chartCanvas
                        width: parent.width
                        height: parent.height - units.gu(3.5)
                        
                        onPaint: {
                            if (weeklyData.length === 0) return;
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);

                            var isDark = root.isDarkMode;
                            var maxVal = 400;
                            for (var i = 0; i < weeklyData.length; i++) {
                                if (weeklyData[i].value > maxVal) {
                                    maxVal = weeklyData[i].value;
                                }
                            }
                            maxVal = Math.ceil(maxVal / 100) * 100;

                            var paddingLeft = units.gu(3.5);
                            var paddingRight = units.gu(2);
                            var paddingBottom = units.gu(2.2);
                            var paddingTop = units.gu(1.5);
                            var chartWidth = width - paddingLeft - paddingRight;
                            var chartHeight = height - paddingBottom - paddingTop;
                            
                            // Horizontal gridlines & axis numbers
                            ctx.strokeStyle = isDark ? "rgba(255, 255, 255, 0.08)" : "rgba(0, 0, 0, 0.06)";
                            ctx.lineWidth = units.dp(1);
                            ctx.font = "10px sans-serif";
                            ctx.fillStyle = isDark ? "#A0A0A5" : "#888888";
                            ctx.textAlign = "right";
                            
                            var steps = 4;
                            for (var j = 0; j <= steps; j++) {
                                var yVal = (maxVal / steps) * j;
                                var yPos = paddingTop + chartHeight - (yVal / maxVal) * chartHeight;
                                
                                ctx.beginPath();
                                ctx.moveTo(paddingLeft, yPos);
                                ctx.lineTo(width - paddingRight, yPos);
                                ctx.stroke();
                                
                                ctx.fillText(Math.round(yVal).toString(), paddingLeft - units.gu(0.8), yPos + 4);
                            }
                            
                            // X-axis Day labels
                            ctx.textAlign = "center";
                            var pointSpacing = weeklyData.length > 1 ? chartWidth / (weeklyData.length - 1) : chartWidth;
                            for (var k = 0; k < weeklyData.length; k++) {
                                var xPos = paddingLeft + k * pointSpacing;
                                ctx.fillText(weeklyData[k].label, xPos, height - 2);
                            }
                            
                            // Area fill gradient
                            ctx.beginPath();
                            ctx.moveTo(paddingLeft, paddingTop + chartHeight - (weeklyData[0].value / maxVal) * chartHeight);
                            for (var m = 1; m < weeklyData.length; m++) {
                                var px = paddingLeft + m * pointSpacing;
                                var py = paddingTop + chartHeight - (weeklyData[m].value / maxVal) * chartHeight;
                                ctx.lineTo(px, py);
                            }
                            ctx.lineTo(paddingLeft + (weeklyData.length - 1) * pointSpacing, paddingTop + chartHeight);
                            ctx.lineTo(paddingLeft, paddingTop + chartHeight);
                            ctx.closePath();
                            
                            var grad = ctx.createLinearGradient(0, paddingTop, 0, paddingTop + chartHeight);
                            grad.addColorStop(0, "rgba(247, 135, 135, 0.35)");
                            grad.addColorStop(1, "rgba(247, 135, 135, 0.0)");
                            ctx.fillStyle = grad;
                            ctx.fill();
                            
                            // Line stroke
                            ctx.beginPath();
                            ctx.moveTo(paddingLeft, paddingTop + chartHeight - (weeklyData[0].value / maxVal) * chartHeight);
                            for (var n = 1; n < weeklyData.length; n++) {
                                var px2 = paddingLeft + n * pointSpacing;
                                var py2 = paddingTop + chartHeight - (weeklyData[n].value / maxVal) * chartHeight;
                                ctx.lineTo(px2, py2);
                            }
                            ctx.strokeStyle = root.primaryColor;
                            ctx.lineWidth = units.dp(2.5);
                            ctx.stroke();
                            
                            // Data point dots
                            for (var p = 0; p < weeklyData.length; p++) {
                                var dotX = paddingLeft + p * pointSpacing;
                                var dotY = paddingTop + chartHeight - (weeklyData[p].value / maxVal) * chartHeight;
                                
                                ctx.beginPath();
                                ctx.arc(dotX, dotY, units.dp(4), 0, 2 * Math.PI, false);
                                ctx.fillStyle = root.primaryColor;
                                ctx.fill();
                                
                                ctx.beginPath();
                                ctx.arc(dotX, dotY, units.dp(2), 0, 2 * Math.PI, false);
                                ctx.fillStyle = isDark ? "#25262B" : "#FFFFFF";
                                ctx.fill();
                            }
                        }
                    }
                }
            }

            // QUICK WORKOUT ACTIONS HERO CARD
            Rectangle {
                width: parent.width
                height: units.gu(13)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)

                Column {
                    anchors.fill: parent
                    anchors.margins: units.gu(1.5)
                    spacing: units.gu(1)

                    RowLayout {
                        width: parent.width

                        Column {
                            Layout.fillWidth: true
                            spacing: units.gu(0.3)

                            Label {
                                text: i18n.tr("Ready to Workout?")
                                font.bold: true
                                font.pixelSize: units.gu(1.8)
                                color: root.textPrimaryColor
                            }

                            Label {
                                text: i18n.tr("Log sets, track rest timers, and hit daily goals.")
                                font.pixelSize: units.gu(1.3)
                                color: root.textSecondaryColor
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                        }
                    }

                    Row {
                        spacing: units.gu(1.5)
                        width: parent.width

                        Button {
                            text: i18n.tr("+ New Workout")
                            color: root.cardBorderColor
                            width: (parent.width - units.gu(1.5)) / 2
                            height: units.gu(4.5)
                            onClicked: {
                                pageLayout.addPageToNextColumn(homePage, Qt.resolvedUrl("SessionCreatePage.qml"), {pageLayout: pageLayout})
                            }
                        }

                        Button {
                            text: i18n.tr("Past Sessions")
                            color: root.cardBorderColor
                            width: (parent.width - units.gu(1.5)) / 2
                            height: units.gu(4.5)
                            onClicked: {
                                pageLayout.addPageToNextColumn(homePage, Qt.resolvedUrl("AddSessionPage.qml"), {pageLayout: pageLayout})
                            }
                        }
                    }

                  

                }
            }

            // Bottom Spacing for FAB
            Item {
                width: parent.width
                height: units.gu(5)
            }
        }
    }

    // FLOATING ACTION BUTTON
    Button {
        id: fab
        iconName: "add"
        color: root.primaryColor
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: units.gu(2.5)
        width: units.gu(5.5)
        height: units.gu(5.5)

        onTriggered: {
            pageLayout.addPageToNextColumn(homePage, Qt.resolvedUrl("SessionCreatePage.qml"), {pageLayout: pageLayout})
        }
    }

    // MET SCIENTIFIC COMPENDIUM GUIDE MODAL
    Rectangle {
        id: metGuideModal
        visible: false
        z: 950
        anchors.fill: parent
        color: "#99000000"

        // Prevent click-through
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Rectangle {
            width: Math.min(parent.width - units.gu(4), units.gu(55))
            height: Math.min(parent.height - units.gu(6), units.gu(68))
            anchors.centerIn: parent
            radius: units.dp(16)
            color: root.cardBgColor
            border.color: root.cardBorderColor
            border.width: units.dp(1)
            clip: true

            Column {
                anchors.fill: parent
                anchors.margins: units.gu(2)
                spacing: units.gu(1.5)

                RowLayout {
                    width: parent.width

                    Row {
                        spacing: units.gu(1)
                        Layout.alignment: Qt.AlignVCenter

                        Label {
                            text: "⚡"
                            font.pixelSize: units.gu(2)
                        }

                        Label {
                            text: i18n.tr("MET Sports Guide")
                            font.bold: true
                            font.pixelSize: units.gu(1.8)
                            color: root.textPrimaryColor
                        }
                    }

                    Item { Layout.fillWidth: true }

                    AbstractButton {
                        width: units.gu(3.5)
                        height: units.gu(3.5)
                        onClicked: metGuideModal.visible = false
                        Rectangle {
                            anchors.fill: parent
                            radius: units.dp(18)
                            color: root.isDarkMode ? "#2C2E33" : "#E9ECEF"
                            Label {
                                anchors.centerIn: parent
                                text: "✕"
                                font.bold: true
                                color: root.textSecondaryColor
                            }
                        }
                    }
                }

                // Formula card
                Rectangle {
                    width: parent.width
                    height: formulaCol.height + units.gu(1.6)
                    radius: units.dp(10)
                    color: root.isDarkMode ? "#1C2438" : "#EBF5FF"
                    border.color: root.secondaryColor
                    border.width: units.dp(1)

                    Column {
                        id: formulaCol
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: units.gu(1)
                        spacing: units.gu(0.4)

                        Label {
                            text: i18n.tr("Scientific Formula:")
                            font.bold: true
                            font.pixelSize: units.gu(1.1)
                            color: root.secondaryColor
                        }

                        Label {
                            text: "Calories = MET × Weight (kg) × Duration (hours)"
                            font.bold: true
                            font.pixelSize: units.gu(1.3)
                            color: root.textPrimaryColor
                        }

                        Label {
                            text: i18n.tr("Standard Compendium of Physical Activities formula used across sports medicine and research.")
                            font.pixelSize: units.gu(1.0)
                            color: root.textSecondaryColor
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }
                    }
                }

                // Scrollable Table of MET values
                Flickable {
                    width: parent.width
                    height: parent.height - formulaCol.height - units.gu(13)
                    contentWidth: width
                    contentHeight: tableCol.height
                    clip: true

                    Column {
                        id: tableCol
                        width: parent.width
                        spacing: units.gu(1.2)

                        // Light Activity
                        Rectangle {
                            width: parent.width
                            height: lightCol.height + units.gu(1.2)
                            radius: units.dp(8)
                            color: root.isDarkMode ? "#1A252C" : "#F0F9FF"
                            border.color: root.secondaryColor
                            border.width: units.dp(1)

                            Column {
                                id: lightCol
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: units.gu(1)
                                spacing: units.gu(0.5)

                                Label {
                                    text: i18n.tr("Light Activity (< 3.0 METs)")
                                    font.bold: true
                                    font.pixelSize: units.gu(1.2)
                                    color: root.secondaryColor
                                }
                                Label { text: "• Sitting / Resting: 1.0 MET (Baseline)"; font.pixelSize: units.gu(1.0); color: root.textPrimaryColor }
                                Label { text: "• Walking slowly (strolling): 2.0 METs"; font.pixelSize: units.gu(1.0); color: root.textPrimaryColor }
                                Label { text: "• Stretching (Hatha Yoga): 2.5 METs"; font.pixelSize: units.gu(1.0); color: root.textPrimaryColor }
                                Label { text: "• Light calisthenics: 2.8 METs"; font.pixelSize: units.gu(1.0); color: root.textPrimaryColor }
                            }
                        }

                        // Moderate Activity
                        Rectangle {
                            width: parent.width
                            height: modCol.height + units.gu(1.2)
                            radius: units.dp(8)
                            color: root.isDarkMode ? "#1B2A22" : "#F0FDF4"
                            border.color: "#22C55E"
                            border.width: units.dp(1)

                            Column {
                                id: modCol
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: units.gu(1)
                                spacing: units.gu(0.5)

                                Label {
                                    text: i18n.tr("Moderate Activity (3.0 – 6.0 METs)")
                                    font.bold: true
                                    font.pixelSize: units.gu(1.2)
                                    color: "#16A34A"
                                }
                                Label { text: "• Weightlifting (moderate gym): 3.5 METs"; font.pixelSize: units.gu(1.0); color: root.textPrimaryColor }
                                Label { text: "• Calisthenics (moderate sets): 3.8 METs"; font.pixelSize: units.gu(1.0); color: root.textPrimaryColor }
                                Label { text: "• Bicycling (leisurely < 10mph): 4.0 METs"; font.pixelSize: units.gu(1.0); color: root.textPrimaryColor }
                                Label { text: "• Power Yoga / Vinyasa: 4.0 METs"; font.pixelSize: units.gu(1.0); color: root.textPrimaryColor }
                                Label { text: "• Walking briskly (3.0 mph): 4.3 METs"; font.pixelSize: units.gu(1.0); color: root.textPrimaryColor }
                            }
                        }

                        // Vigorous Activity
                        Rectangle {
                            width: parent.width
                            height: vigCol.height + units.gu(1.2)
                            radius: units.dp(8)
                            color: root.isDarkMode ? "#2D1D1C" : "#FFF7ED"
                            border.color: "#F97316"
                            border.width: units.dp(1)

                            Column {
                                id: vigCol
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: units.gu(1)
                                spacing: units.gu(0.5)

                                Label {
                                    text: i18n.tr("Vigorous Activity (> 6.0 METs)")
                                    font.bold: true
                                    font.pixelSize: units.gu(1.2)
                                    color: "#EA580C"
                                }
                                Label { text: "• Heavy Weightlifting / Powerlifting: 6.0 METs"; font.pixelSize: units.gu(1.0); color: root.textPrimaryColor }
                                Label { text: "• Circuit Training / HIIT: 8.0 METs"; font.pixelSize: units.gu(1.0); color: root.textPrimaryColor }
                                Label { text: "• Jogging (5.0 mph / 8 km/h): 8.3 METs"; font.pixelSize: units.gu(1.0); color: root.textPrimaryColor }
                                Label { text: "• Running (6.0 mph / 9.6 km/h): 9.8 METs"; font.pixelSize: units.gu(1.0); color: root.textPrimaryColor }
                                Label { text: "• Vigorous Bicycling (14-15 mph): 10.0 METs"; font.pixelSize: units.gu(1.0); color: root.textPrimaryColor }
                                Label { text: "• Jump Rope (moderate pace): 11.5 METs"; font.pixelSize: units.gu(1.0); color: root.textPrimaryColor }
                            }
                        }
                    }
                }

                Button {
                    text: i18n.tr("Understood")
                    color: root.primaryColor
                    width: parent.width
                    height: units.gu(4.5)
                    onClicked: metGuideModal.visible = false
                }
            }
        }
    }

    ExportReportModal {
        id: exportModalItem
    }
}