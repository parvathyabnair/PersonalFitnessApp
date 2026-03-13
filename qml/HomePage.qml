import QtQuick 2.7
import Lomiri.Components 1.3
//import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0


 Page {
        anchors.fill: parent
visible: !showSplash
        header: PageHeader {
            id: header
            title: i18n.tr('Fitness App')

         StyleHints {
            foregroundColor: "white"
             backgroundColor: '#f78787'
            dividerColor: LomiriColors.slate
        }
            
        

        trailingActionBar.numberOfSlots: 2
            trailingActionBar.actions: [
                Action {
                iconName: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "weather-clear-night-symbolic" : "weather-clear-symbolic"
                text: theme.name === "Ubuntu.Components.Themes.SuruDark" ? i18n.tr("Light Mode") : i18n.tr("Dark Mode")
                onTriggered: {
                    var newTheme = theme.name === "Ubuntu.Components.Themes.SuruDark" ? "Ubuntu.Components.Themes.Ambiance" : "Ubuntu.Components.Themes.SuruDark";
                    Theme.name = newTheme;

                
                }
            },
              
               Action {
    iconName: "add"
    text: "Add Session"

    onTriggered: {
        pageStack.push(Qt.resolvedUrl("AddSessionPage.qml"))
    }
},
//            Action {
//     iconName: "notification"
//     text: "Notification"

   
// },

                 Action {
                    iconName: "info"
                    text: i18n.tr("Active Session")
                    onTriggered: {
        pageStack.push(Qt.resolvedUrl("ActiveSessionPage.qml"))
    }
                },

                 Action {
                    iconName: "settings"
                    text: i18n.tr("Settings")
                    onTriggered: {
        pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
    }
                }
            ]
        }

        Label {
            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            text: i18n.tr('Hello!')

            verticalAlignment: Label.AlignVCenter
            horizontalAlignment: Label.AlignHCenter
        }
    }