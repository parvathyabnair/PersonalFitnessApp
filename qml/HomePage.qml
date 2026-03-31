import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
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
                      i18n.tr("Light Mode") :
                      i18n.tr("Dark Mode")

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

    Row {
        id: overviewCards
        anchors.top: dateLabel.bottom
        anchors.topMargin: units.gu(4)
        anchors.horizontalCenter: parent.horizontalCenter
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
                    text: i18n.tr("Todays Weight")
                    font.pixelSize: units.gu(1.2)
                    color: "gray"
                    //font.bold: true
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
                    //color: "gray"
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

    Column {
        id: progressContainer
        anchors.top: overviewCards.bottom
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