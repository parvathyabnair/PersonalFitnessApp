import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import QtQuick.Shapes 1.0
import Qt.labs.settings 1.0
import "database.js" as DB

Page {
    anchors.fill: parent
    property var pageLayout
    property string currentWeight: "0"
    property string todaysCalories: "0"
    property string goalWeight: "0"
    property real targetCalories: 1
    property real progressPercentage: 0
    property var weeklyData: []

    function loadOverviewData() {
        var settings = DB.getSettings()
        if (settings) {
            currentWeight = settings.weight ? settings.weight : "0"
            goalWeight = settings.goal_weight ? settings.goal_weight : "0"
            targetCalories = parseFloat(settings.kcal_target) || 1
        }
        var cal = DB.getTodaysCalories()
        todaysCalories = Math.round(cal).toString()
        var pct = (cal / targetCalories) * 100
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
        title: i18n.tr("Fitness App")

        StyleHints {
            foregroundColor: "white"
            backgroundColor: "#f78787"
            dividerColor: LomiriColors.slate
        }

        trailingActionBar.numberOfSlots: 2

        trailingActionBar.actions: [

            Action {
                iconName: theme.name === "Ubuntu.Components.Themes.SuruDark" ?
                          "weather-clear-night-symbolic" :
                          "weather-clear-symbolic"

                text: theme.name === "Ubuntu.Components.Themes.SuruDark" ?
                      i18n.tr("Light Mode") :  i18n.tr("Dark Mode")

                onTriggered: {
                    var newTheme =
                        theme.name === "Ubuntu.Components.Themes.SuruDark" ?
                        "Ubuntu.Components.Themes.Ambiance" :
                        "Ubuntu.Components.Themes.SuruDark"

                    Theme.name = newTheme
                }
            },

            Action {
                iconName: "add"
                text: "Session Overview"

                onTriggered: {
                    pageLayout.addPageToNextColumn(pageLayout.primaryPage,Qt.resolvedUrl("AddSessionPage.qml"),{pageLayout: pageLayout})
                }
            },

            Action {
                iconName: "info"
                text: i18n.tr("Active Session")

                onTriggered: {
                    pageLayout.addPageToNextColumn(pageLayout.primaryPage,Qt.resolvedUrl("ActiveSessionPage.qml"),{pageLayout: pageLayout})
                }
            },

            Action {
                iconName: "settings"
                text: i18n.tr("Settings")

                onTriggered: {
                    pageLayout.addPageToNextColumn(pageLayout.primaryPage,Qt.resolvedUrl("SettingsPage.qml"))
                }
            }
        ]
    }

    Label {
        id: dateLabel
        anchors.top: header.bottom
        anchors.topMargin: units.gu(2)
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDate(new Date(), "dddd, d MMMM yyyy")
        font.pixelSize: units.gu(2.5)
        font.bold: true
    }
    Item {
        id: overviewCards
        anchors.top: dateLabel.bottom
        anchors.topMargin: units.gu(4)
        anchors.horizontalCenter: parent.horizontalCenter
        width: cardsRow.width + units.gu(4)
        height: cardsRow.height + units.gu(4)

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: '#d5cccc'
            border.width: units.dp(2)
            radius: units.dp(8)
        }

        Rectangle {
            id: animatedCircle
            width: units.gu(2)
            height: units.gu(2)
            radius: width / 2
            color: "#f78787"
            z: 2
            x: 0
            y: 0
        }

        SequentialAnimation {
            loops: Animation.Infinite
            running: true

            NumberAnimation { target: animatedCircle; property: "x"; from: 0; to: overviewCards.width - animatedCircle.width; duration: 2000 }
            NumberAnimation { target: animatedCircle; property: "y"; from: 0; to: overviewCards.height - animatedCircle.height; duration: 1000 }
            NumberAnimation { target: animatedCircle; property: "x"; from: overviewCards.width - animatedCircle.width; to: 0; duration: 2000 }
            NumberAnimation { target: animatedCircle; property: "y"; from: overviewCards.height - animatedCircle.height; to: 0; duration: 1000 }
        }

        Row {
            id: cardsRow
            anchors.centerIn: parent
            spacing: units.gu(1.5)

            // Today's Weight Card
            Rectangle {
                width: units.gu(10)
                height: units.gu(9)
                radius: units.dp(8)
                border.color: "#E0E0E0"
                border.width: units.dp(1)
                color: "#b4dff0"

                Column {
                    anchors.centerIn: parent
                    spacing: units.gu(0.5)

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: currentWeight + "kg"
                        font.pixelSize: units.gu(2.8)
                        font.bold: true
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: i18n.tr("Current Weight")
                        font.pixelSize: units.gu(1.2)
                        color: "gray"
                    }
                }
            }

            // Today's Calories Card
            Rectangle {
                width: units.gu(10)
                height: units.gu(9)
                radius: units.dp(8)
                border.color: "#E0E0E0"
                border.width: units.dp(1)
                color: "#b4dff0"

                Column {
                    anchors.centerIn: parent
                    spacing: units.gu(0.5)

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: todaysCalories + "kcal"
                        font.pixelSize: units.gu(2.8)
                        font.bold: true
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: i18n.tr("Todays Calories")
                        font.pixelSize: units.gu(1.2)
                        color: "gray"
                    }
                }
            }

            // Goal Weight Card
            Rectangle {
                width: units.gu(10)
                height: units.gu(9)
                radius: units.dp(8)
                border.color: "#E0E0E0"
                border.width: units.dp(1)
                color: "#b4dff0"

                Column {
                    anchors.centerIn: parent
                    spacing: units.gu(0.5)

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: goalWeight + "kg"
                        font.pixelSize: units.gu(2.8)
                        font.bold: true
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: i18n.tr("Goal")
                        font.pixelSize: units.gu(1.2)
                        color: "gray"
                    }
                }
            }
        }
    }

    Rectangle {
        id: weeklyChartRect
        anchors.top: overviewCards.bottom
        anchors.topMargin: units.gu(3)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: units.gu(4)
        anchors.rightMargin: units.gu(4)
        height: units.gu(28)
        radius: units.dp(8)
        border.color: "#E0E0E0"
        border.width: units.dp(1)
        color: "white"

        Label {
            id: chartTitle
            anchors.top: parent.top
            anchors.topMargin: units.gu(2)
            anchors.horizontalCenter: parent.horizontalCenter
            text: i18n.tr("Weekly Progress")
            font.bold: true
            font.pixelSize: units.gu(2.0)
        }

        Canvas {
            id: chartCanvas
            anchors.top: chartTitle.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: units.gu(2)
            
            onPaint: {
                if (weeklyData.length === 0) return;
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                // calculate max value for y scaling
                var maxVal = 500; // default min max
                for (var i = 0; i < weeklyData.length; i++) {
                    if (weeklyData[i].value > maxVal) {
                        maxVal = weeklyData[i].value;
                    }
                }
                maxVal = Math.ceil(maxVal / 100) * 100;

                var paddingLeft = units.gu(4);
                var paddingBottom = units.gu(2);
                var chartWidth = width - paddingLeft;
                var chartHeight = height - paddingBottom;
                
                // Draw horizontal grid lines and labels
                ctx.strokeStyle = "#F0F0F0";
                ctx.lineWidth = units.dp(1);
                ctx.font = "10px sans-serif";
                ctx.fillStyle = "gray";
                ctx.textAlign = "right";
                
                var steps = 5;
                for (var j = 1; j <= steps; j++) {
                    var yVal = (maxVal / steps) * j;
                    var yPos = chartHeight - (yVal / maxVal) * chartHeight;
                    
                    ctx.beginPath();
                    ctx.moveTo(paddingLeft, yPos);
                    ctx.lineTo(width, yPos);
                    ctx.stroke();
                    
                    ctx.fillText(yVal.toString(), paddingLeft - units.gu(1), yPos + 4);
                }
                
                // Draw x-axis labels
                ctx.textAlign = "center";
                var pointSpacing = chartWidth / (weeklyData.length - 1);
                for (var k = 0; k < weeklyData.length; k++) {
                    var xPos = paddingLeft + k * pointSpacing;
                    ctx.fillText(weeklyData[k].label, xPos, height - 2);
                }
                
                // Draw line chart
                ctx.beginPath();
                ctx.moveTo(paddingLeft, chartHeight - (weeklyData[0].value / maxVal) * chartHeight);
                for (var m = 1; m < weeklyData.length; m++) {
                    var px = paddingLeft + m * pointSpacing;
                    var py = chartHeight - (weeklyData[m].value / maxVal) * chartHeight;
                    ctx.lineTo(px, py);
                }
                
                // Area fill gradient
                ctx.lineTo(paddingLeft + (weeklyData.length - 1) * pointSpacing, chartHeight);
                ctx.lineTo(paddingLeft, chartHeight);
                ctx.closePath();
                
                var grad = ctx.createLinearGradient(0, 0, 0, chartHeight);
                grad.addColorStop(0, "rgba(42, 130, 240, 0.3)");
                grad.addColorStop(1, "rgba(42, 130, 240, 0.0)");
                ctx.fillStyle = grad;
                ctx.fill();
                
                // Draw line again over the area
                ctx.beginPath();
                ctx.moveTo(paddingLeft, chartHeight - (weeklyData[0].value / maxVal) * chartHeight);
                for (var n = 1; n < weeklyData.length; n++) {
                    var px2 = paddingLeft + n * pointSpacing;
                    var py2 = chartHeight - (weeklyData[n].value / maxVal) * chartHeight;
                    ctx.lineTo(px2, py2);
                }
                ctx.strokeStyle = "rgba(42, 130, 240, 1.0)";
                ctx.lineWidth = units.dp(3);
                ctx.stroke();
                
                // Draw latest point dot
                if (weeklyData.length > 0) {
                    var lastX = paddingLeft + (weeklyData.length - 1) * pointSpacing;
                    var lastY = chartHeight - (weeklyData[weeklyData.length - 1].value / maxVal) * chartHeight;
                    ctx.beginPath();
                    ctx.arc(lastX, lastY, units.dp(5), 0, 2 * Math.PI, false);
                    ctx.fillStyle = "rgba(42, 130, 240, 1.0)";
                    ctx.fill();
                    
                    ctx.beginPath();
                    ctx.arc(lastX, lastY, units.dp(8), 0, 2 * Math.PI, false);
                    ctx.fillStyle = "rgba(42, 130, 240, 0.3)";
                    ctx.fill();
                }
            }
        }
    }

    Column {
        id: progressContainer
        anchors.top: weeklyChartRect.bottom
        anchors.topMargin: units.gu(4)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: units.gu(4)
        anchors.rightMargin: units.gu(4)
        spacing: units.gu(1)

        RowLayout {
            width: parent.width

            Label {
                text: i18n.tr("Workout Progress for today")
                font.bold: true
                font.pixelSize: units.gu(1.6)
            }
            Item { Layout.fillWidth: true }
            Label {
                text: progressPercentage + i18n.tr("% Complete")
                font.bold: true
                font.pixelSize: units.gu(1.4)
            }
        }

        Rectangle {
            width: parent.width
            height: units.gu(1.2)
            radius: height / 2
            color: "#E0E0E0"

            Rectangle {
                width: parent.width * (progressPercentage / 100)
                height: parent.height
                radius: parent.radius
                color: "#f78787"
            }
        }
    }

    /* Swipe Gesture */

    MultiPointTouchArea {
        anchors.fill: parent

        property real startY

        onPressed: {
            startY = touchPoints[0].y
        }

        onReleased: {

            var endY = touchPoints[0].y

            if (startY - endY > 120) {

                console.log("Swipe Up Detected")

                pageLayout.addPageToNextColumn(pageLayout.primaryPage,Qt.resolvedUrl("SessionCreatePage.qml"),
    {
        pageLayout: pageLayout    
    }
)
            }
        }
    }

    /* Swipe Up Hint */

    Column {
    width: parent.width
    anchors.bottom: parent.bottom
    anchors.bottomMargin: units.gu(3)

    spacing: units.gu(1)

    //horizontalAlignment: Text.AlignHCenter

    Icon {
        name: "go-up"
        width: units.gu(3)
        height: units.gu(3)
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Label {
        text: i18n.tr("Swipe up to start new session")
        anchors.horizontalCenter: parent.horizontalCenter
        font.bold: true
    }
}
Button {
            id: fab
             iconName: "add"
            color: "#f78787"
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: units.gu(2)
            width: units.gu(5)
            height: units.gu(5)
            font.pixelSize: units.gu(4)
            onTriggered: {
                console.log("FAB Clicked - Create new item")
                pageLayout.addPageToNextColumn(pageLayout.primaryPage,Qt.resolvedUrl("SessionCreatePage.qml"),
    {
        pageLayout: pageLayout    
    }
)
            }
        }
}