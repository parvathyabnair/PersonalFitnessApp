import QtQuick 2.7
import Lomiri.Components 1.3
//import QtQuick.Window 2.2
import QtQml.Models 2.3
//import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0
//mport "components"
import "database.js" as DB

Page {
    header: PageHeader {
        title: i18n.tr("Session Overview")
        trailingActionBar.numberOfSlots: 1
        

         StyleHints {
            foregroundColor: "white"
             backgroundColor: '#f78787'
            dividerColor: LomiriColors.slate
        }
            trailingActionBar.actions: [
        
              
               Action {
    iconName: "add"
    text: i18n.tr(" Session Overview")

    onTriggered: {
        pageLayout.addPageToNextColumn(pageLayout.primaryPage,Qt.resolvedUrl("SessionCreatePage.qml"))


    }
}]
    }
    Flickable {
        anchors.fill: parent
        anchors.topMargin: header.height + units.gu(0.5)
    ListModel {
        id: sessionModel
        
       
    }

Component.onCompleted: {

    var sessions = DB.getSessions()
  

    for(var i=0; i<sessions.length; i++) {

    sessionModel.append({
    id: sessions[i].id,
    workout: sessions[i].workout,
    sets: sessions[i].sets,
    weight: sessions[i].weight,
    date: sessions[i].date
})
    }
      //var weightsArray = JSON.parse(weight)
}


ListView {
    anchors.fill: parent
    model: sessionModel


    delegate: ListItem {

    width: parent.width
    height: units.gu(8)
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
                text: {
                    var weightsArray = JSON.parse(model.weight)
                    return "Weights: " + weightsArray.join(", ")
                }
            }
        }

        Label {
            text: new Date(model.date).toLocaleDateString(Qt.locale(), "MMMM d, yyyy")

            anchors.verticalCenter: parent.verticalCenter
            color: LomiriColors.slate
            font.bold: true
        }
    }
}
}


}}