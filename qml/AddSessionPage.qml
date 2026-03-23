import QtQuick 2.7
import Lomiri.Components 1.3
//import QtQuick.Window 2.2
import QtQml.Models 2.3
//import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0
//mport "components"
import "database.js" as DB

Page {
    property var pageLayout
    property bool showSearch: false
    header: PageHeader {
        title: i18n.tr("Session Overview")
        trailingActionBar.numberOfSlots: 2
        

         StyleHints {
            foregroundColor: "white"
             backgroundColor: '#f78787'
            dividerColor: LomiriColors.slate
        }
            trailingActionBar.actions: [
        
              
               Action {
    iconName: "find"
    text: i18n.tr("Search")
    onTriggered: {
        showSearch = !showSearch
        if (!showSearch) {
            refreshModel("")
        }
    }
},
               Action {
    iconName: "add"
    text: i18n.tr(" Session Overview")

    onTriggered: {
        pageLayout.addPageToNextColumn(
    pageLayout.primaryPage,Qt.resolvedUrl("SessionCreatePage.qml"),
    {
        pageLayout: pageLayout   
    }
)


    }
}]
    }
    function refreshModel(query) {
        sessionModel.clear()
        var sessions = DB.getSessions(query)
        for(var i=0; i<sessions.length; i++) {
            sessionModel.append({
                id: sessions[i].id,
                workout: sessions[i].workout,
                sets: sessions[i].sets,
                weight: sessions[i].weight,
                date: sessions[i].date,
                duration: sessions[i].duration,
                calories: sessions[i].calories
            })
        }
    }

    Component.onCompleted: {
        refreshModel("")
    }

    ListModel {
        id: sessionModel
    }


    Column {
        anchors.fill: parent
        anchors.topMargin: header.height + units.gu(0.5)

        TextField {
            id: searchField
            visible: showSearch
            placeholderText: i18n.tr("Search workouts...")
            width: parent.width
            anchors.margins: units.gu(1)
            onTextChanged: refreshModel(text)
        }

        ListView {
            width: parent.width
            height: parent.height - (searchField.visible ? searchField.height : 0)
            model: sessionModel
            clip: true


    delegate: ListItem {

    width: parent.width
    height: units.gu(10)
      leadingActions: ListItemActions {
                    actions: [
                        Action {
                            iconName: "delete"
                            onTriggered: {
    DB.deleteSession(model.id)
    sessionModel.remove(index)
}
                            
                        }
                        
                    ]
                    
                }

                trailingActions: ListItemActions {
                    actions: [
                        Action {
                            iconName: "edit"
   onTriggered: {
    pageLayout.addPageToNextColumn(
    pageLayout.primaryPage,
    Qt.resolvedUrl("SessionCreatePage.qml"),
    {
        pageLayout: pageLayout,   
        isEditMode: true,
        sessionId: model.id,
        workout: model.workout,
        sets: model.sets,
        weight: model.weight,
        date: model.date
    }
)
}
                        }
                    ]
                }

    

Row {
        anchors.fill: parent
        anchors.margins: units.gu(1)
        
Column {
            width: parent.width - units.gu(12)
            

            Label { 
                text: model.workout
             font.bold: true 
             }
            Label { 
                text: "Sets: " + model.sets
                 }

                 Label {
    text: "Time: " + formatTime(model.duration)
}
 Label {
                text: {
                    var weightsArray = JSON.parse(model.weight)
                    return "Weights: " + weightsArray.join(", ")
                }
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            
            Label {
                text: Qt.formatDate(new Date(model.date), "MM/dd/yyyy")
                color: LomiriColors.slate
                font.bold: true
            }

            Label {
                text: model.calories ? model.calories.toFixed(2) + " kcal" : "0.00 kcal"
                color: "#f78787" // Matching theme color
                font.pixelSize: units.gu(1.5)
                horizontalAlignment: Text.AlignRight
                width: parent.width
            }
        }
    }
        }
    }
}
function formatTime(sec) {
    if (!sec) return "00:00:00"

    var hours = Math.floor(sec / 3600)
    var mins = Math.floor((sec % 3600) / 60)
    var secs = sec % 60
    return ("0" + hours).slice(-2) + ":" + ("0" + mins).slice(-2) + ":" + ("0" + secs).slice(-2)
}

}