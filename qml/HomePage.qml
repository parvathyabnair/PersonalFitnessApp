import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0

Page {
    anchors.fill: parent
property var pageLayout
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
                text: "Add Session"

                onTriggered: {
                    pageLayout.addPageToNextColumn(pageLayout.primaryPage,Qt.resolvedUrl("AddSessionPage.qml"))
                }
            },

            Action {
                iconName: "info"
                text: i18n.tr("Active Session")

                onTriggered: {
                    pageLayout.addPageToNextColumn(pageLayout.primaryPage,Qt.resolvedUrl("ActiveSessionPage.qml"))
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
        anchors.centerIn: parent
        text: i18n.tr("Hello!")
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

                pageLayout.push(Qt.resolvedUrl("SessionCreatePage.qml"))
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
        text: i18n.tr("Swipe up to start session")
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
}