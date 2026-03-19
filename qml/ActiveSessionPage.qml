import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtQuick.Layouts 1.3
import "database.js" as DB

Page {
    id: activePage

    // REQUIRED PROPERTIES
    property var pageLayout
    property int sessionId: -1
    property string workout: "Workout"

    // TIMER PROPERTIES
    property int secondsElapsed: 0
    property bool isRunning: true

    // NEXT EXERCISE CONFIRM FLAG
    property bool confirmNext: false
    property bool isSaved: false

    // FORMAT TIME
    property string timeString: {
        var mins = Math.floor(secondsElapsed / 60)
        var secs = secondsElapsed % 60
        return ("0" + mins).slice(-2) + ":" + ("0" + secs).slice(-2)
    }

    header: PageHeader {
        title: i18n.tr("Active Session")

        StyleHints {
            foregroundColor: "white"
            backgroundColor: "#f78787"
        }

           trailingActionBar.numberOfSlots: 2
            trailingActionBar.actions: [
               
              
               Action {
    iconName: "save"
    text: i18n.tr("Save Session")

           onTriggered: {
    var timeTaken = secondsElapsed

    console.log("Saving time:", timeTaken)

    DB.updateSessionTime(sessionId, timeTaken)

    isSaved = true   

    PopupUtils.open(savedDialog)
}

    
}]
    }

    // TIMER
    Timer {
        interval: 1000
        running: isRunning
        repeat: true
        onTriggered: secondsElapsed++
    }

    //  MAIN UI (CENTERED)
    Column {
        anchors.centerIn: parent
        spacing: units.gu(3)

        //  WORKOUT NAME
        Label {
            text: workout
            font.bold: true
            font.pixelSize: units.gu(3)
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // TIMER DISPLAY
        Label {
            text: timeString
            font.pixelSize: units.gu(6)
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        //  BUTTONS
        Row {
            spacing: units.gu(2)
            anchors.horizontalCenter: parent.horizontalCenter

            Button {
                text: isRunning ? "Stop" : "Resume"
                onClicked: isRunning = !isRunning
            }

            Button {
                text: "Next Exercise"
                onClicked: handleNextExercise()
            }
        }


    }

    //  NEXT EXERCISE FUNCTION
   function handleNextExercise() {

    if (!isSaved) {
        PopupUtils.open(confirmDialog)   
        return
    }

    // ALLOW NAVIGATION ONLY AFTER SAVE
    pageLayout.addPageToNextColumn(
        activePage,
        Qt.resolvedUrl("SessionCreatePage.qml"),
        {
            pageLayout: pageLayout
        }
    )
}

    //  CONFIRM DIALOG
    Component {
        id: confirmDialog

        Dialog {
            id: dialog
            title: "Save Session"

            Column {
                spacing: units.gu(2)

                Label {
                 
                    width: parent.width
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignJustify
        text: i18n.tr("Save the session before starting")
                }

                Button {
                    text: "OK"
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: PopupUtils.close(dialog)
                }
            }
        }
    }

    //  SAVED SUCCESS DIALOG
    Component {
        id: savedDialog

        Dialog {
            id: dialogBox
            title: "Success"

            Column {
                spacing: units.gu(2)

                Label {
                   
                       width: parent.width
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignJustify
        text: i18n.tr("Session saved successfully!")
                    
                }

                Button {
                    text: "OK"
                    anchors.horizontalCenter: parent.horizontalCenter

                    onClicked: {
                        PopupUtils.close(dialogBox)
                    }
                }
            }
        }
    }
}