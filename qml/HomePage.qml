import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
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
    }

    Component.onCompleted: {
        loadOverviewData()
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
                    pageLayout.addPageToNextColumn(pageLayout.primaryPage, Qt.resolvedUrl("ActiveSessionPage.qml"), {pageLayout: pageLayout})
                }
            },

            Action {
                iconSource: Qt.resolvedUrl("../assets/show.png")
                text: i18n.tr("Session Overview")

                onTriggered: {
                    pageLayout.addPageToNextColumn(pageLayout.primaryPage, Qt.resolvedUrl("AddSessionPage.qml"), {pageLayout: pageLayout})
                }
            },

            Action {
                iconName: "settings"
                text: i18n.tr("Settings")

                onTriggered: {
                    pageLayout.addPageToNextColumn(pageLayout.primaryPage, Qt.resolvedUrl("SettingsPage.qml"))
                }
            },

            Action {
                iconName: "find"
                text: i18n.tr("Wearables & Band 9")

                onTriggered: {
                    pageLayout.addPageToNextColumn(pageLayout.primaryPage, Qt.resolvedUrl("WearablesPage.qml"), {pageLayout: pageLayout})
                }
            },

            Action {
                iconSource: Qt.resolvedUrl("../assets/show.png")
                text: i18n.tr("Private Media Vault 🔒")

                onTriggered: {
                    pageLayout.addPageToNextColumn(pageLayout.primaryPage, Qt.resolvedUrl("MediaVaultPage.qml"), {pageLayout: pageLayout})
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

                    Label {
                        text: i18n.tr("Welcome Back! 💪")
                        font.pixelSize: units.gu(2.4)
                        font.bold: true
                        color: root.textPrimaryColor
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

            // WEARABLE SENSOR QUICK BANNER (Xiaomi Band 9)
            Rectangle {
                width: parent.width
                height: units.gu(5.5)
                radius: units.dp(10)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: units.gu(1.5)
                    anchors.rightMargin: units.gu(1.5)
                    spacing: units.gu(1.2)

                    Label {
                        text: "⌚"
                        font.pixelSize: units.gu(2.2)
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: units.gu(0.1)

                        Row {
                            spacing: units.gu(0.8)

                            Label {
                                text: root.backendBridge.deviceName
                                font.bold: true
                                font.pixelSize: units.gu(1.3)
                                color: root.textPrimaryColor
                            }

                            Rectangle {
                                width: units.gu(0.8)
                                height: units.gu(0.8)
                                radius: width / 2
                                color: root.backendBridge.connected ? "#10B981" : "#EF4444"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Label {
                            text: root.backendBridge.connected ?
                                  ("❤️ " + root.backendBridge.heartRate + " BPM (" + root.backendBridge.heartRateZone + ") • 👣 " + root.backendBridge.steps.toLocaleString() + " steps") :
                                  i18n.tr("Device Disconnected • Tap to pair")
                            font.pixelSize: units.gu(1.1)
                            color: root.textSecondaryColor
                        }
                    }

                    Icon {
                        name: "next"
                        width: units.gu(1.8)
                        height: units.gu(1.8)
                        color: root.textSecondaryColor
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        pageLayout.addPageToNextColumn(pageLayout.primaryPage, Qt.resolvedUrl("WearablesPage.qml"), {pageLayout: pageLayout})
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
                        color: root.accentOrange
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: units.gu(0.4)
                        width: parent.width - units.gu(1)

                        Label {
                            text: "🔥"
                            font.pixelSize: units.gu(2)
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
                        color: root.accentBlue
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: units.gu(0.4)
                        width: parent.width - units.gu(1)

                        Label {
                            text: "⚖️"
                            font.pixelSize: units.gu(2)
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

                        Label {
                            text: "🎯"
                            font.pixelSize: units.gu(2)
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
                            grad.addColorStop(0, "rgba(255, 82, 82, 0.35)");
                            grad.addColorStop(1, "rgba(255, 82, 82, 0.0)");
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
                            ctx.strokeStyle = "#FF5252";
                            ctx.lineWidth = units.dp(2.5);
                            ctx.stroke();
                            
                            // Data point dots
                            for (var p = 0; p < weeklyData.length; p++) {
                                var dotX = paddingLeft + p * pointSpacing;
                                var dotY = paddingTop + chartHeight - (weeklyData[p].value / maxVal) * chartHeight;
                                
                                ctx.beginPath();
                                ctx.arc(dotX, dotY, units.dp(4), 0, 2 * Math.PI, false);
                                ctx.fillStyle = "#FF5252";
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
                            color: root.primaryColor
                            width: (parent.width - units.gu(1.5)) / 2
                            height: units.gu(4.5)
                            onClicked: {
                                pageLayout.addPageToNextColumn(pageLayout.primaryPage, Qt.resolvedUrl("SessionCreatePage.qml"), {pageLayout: pageLayout})
                            }
                        }

                        Button {
                            text: i18n.tr("Past Sessions")
                            color: root.cardBorderColor
                            width: (parent.width - units.gu(1.5)) / 2
                            height: units.gu(4.5)
                            onClicked: {
                                pageLayout.addPageToNextColumn(pageLayout.primaryPage, Qt.resolvedUrl("AddSessionPage.qml"), {pageLayout: pageLayout})
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
            pageLayout.addPageToNextColumn(pageLayout.primaryPage, Qt.resolvedUrl("SessionCreatePage.qml"), {pageLayout: pageLayout})
        }
    }
}