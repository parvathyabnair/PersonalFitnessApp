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

    // TIMER PROPERTIES (BIND TO GLOBAL)
    property int secondsElapsed: root.activeSessionSeconds
    property bool isRunning: root.activeSessionRunning

    // NEXT EXERCISE CONFIRM FLAG
    property bool confirmNext: false
    property bool isSaved: false
    property real caloriesBurned: 0.0

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
    enabled: root.activeSessionId !== -1

           onTriggered: {
    var timeTaken = root.activeSessionSeconds
    var weight = 70 // default
    var settings = DB.getSettings()
    if (settings && settings.weight) {
        weight = parseFloat(settings.weight)
    }

    // Calories burned = MET (4) * weight (kg) * duration (hours)
    var durationHours = timeTaken / 3600
    caloriesBurned = 4 * weight * durationHours

    console.log("Saving time:", timeTaken)
    console.log("Calculated calories:", caloriesBurned)

    DB.updateSessionTime(root.activeSessionId, timeTaken)
    DB.updateSessionCalories(root.activeSessionId, caloriesBurned)

    isSaved = true   
    root.activeSessionRunning = false

    PopupUtils.open(savedDialog)
}

    
}]
    }

    // NO ACTIVE SESSIONS VIEW
    Label {
        anchors.centerIn: parent
        text: i18n.tr("No active sessions")
        visible: root.activeSessionId === -1
        font.pixelSize: units.gu(3)
        color: LomiriColors.slate
    }

    //  MAIN UI (CENTERED)
    Column {
        anchors.centerIn: parent
        spacing: units.gu(3)
        visible: root.activeSessionId !== -1

        //  WORKOUT NAME
        Label {
            text: root.activeSessionWorkout
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
                text: root.activeSessionRunning ? "Stop" : "Resume"
                onClicked: root.activeSessionRunning = !root.activeSessionRunning
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

    // CLEAR GLOBAL SESSION STATE AS WE ARE STARTING A NEW ONE
    root.activeSessionId = -1
    root.activeSessionRunning = false
    root.activeSessionSeconds = 0

    // ALLOW NAVIGATION ONLY AFTER SAVE
    pageLayout.addPageToNextColumn(pageLayout.primaryPage,Qt.resolvedUrl("SessionCreatePage.qml"),
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
        text: i18n.tr("Stop and Save the session before starting")
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
        text: i18n.tr("Session saved successfully! Your total calories burned for this session is " + caloriesBurned.toFixed(2) + " kcal.")
                    
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