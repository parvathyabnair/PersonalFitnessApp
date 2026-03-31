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
        
        var today = new Date()
        var todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate())
        var todayEnd = new Date(todayStart.getTime() + 24 * 60 * 60 * 1000)
        
        var weekStart = new Date(todayStart.getTime() - today.getDay() * 24 * 60 * 60 * 1000)
        var monthStart = new Date(today.getFullYear(), today.getMonth(), 1)
        
        for(var i=0; i<sessions.length; i++) {
            var s = sessions[i]
            var sessionDate = new Date(s.date)
            var sessionDateStart = new Date(sessionDate.getFullYear(), sessionDate.getMonth(), sessionDate.getDate())
            
            var include = true
            if (topFilterBar.currentFilter === topFilterBar.filter1) { 
                if (sessionDateStart < todayStart || sessionDateStart >= todayEnd) include = false
            } else if (topFilterBar.currentFilter === topFilterBar.filter2) { 
                if (sessionDateStart < weekStart || sessionDateStart >= todayEnd) include = false 
            } else if (topFilterBar.currentFilter === topFilterBar.filter3) { 
                if (sessionDateStart < monthStart || sessionDateStart >= todayEnd) include = false
            }
            
            if (include) {
                sessionModel.append({
                    id: s.id,
                    workout: s.workout,
                    sets: s.sets,
                    weight: s.weight,
                    date: s.date,
                    duration: s.duration,
                    calories: s.calories
                })
            }
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

        Rectangle {
            id: topFilterBar
            width: parent.width
            height: units.gu(4)
            //color: '#cea8a8'

            property string label1: "Today"
            property string label2: "This Week"
            property string label3: "This Month"
            property string label6: "All"

            property string filter1: "today"
            property string filter2: "this_week"
            property string filter3: "this_month"
            property string filter6: "all"

            property string currentFilter: filter1

            signal filterSelected(string filterKey)
            
            onFilterSelected: {
                refreshModel(searchField.visible ? searchField.text : "")
            }

            Flickable {
                id: flickable
                width: parent.width
                height: units.gu(4)
                contentWidth: rowLayout.width
                contentHeight: rowLayout.height
                clip: true
                flickableDirection: Flickable.HorizontalFlick

                Row {
                    id: rowLayout
                    spacing: 1

                    Button {
                        text: topFilterBar.label1
                        width: units.gu(11)
                        height: units.gu(4)
                        property bool isHighlighted: topFilterBar.currentFilter === topFilterBar.filter1
                        color: isHighlighted ? "#f78787" : "#b4dff0"

                        onClicked: {
                            topFilterBar.currentFilter = topFilterBar.filter1
                            topFilterBar.filterSelected(topFilterBar.filter1)
                        }
                    }

                    Button {
                        text: topFilterBar.label2
                        width: units.gu(11)
                        height: units.gu(4)
                        property bool isHighlighted: topFilterBar.currentFilter === topFilterBar.filter2
                        color: isHighlighted ? "#f78787" : "#b4dff0"

                        onClicked: {
                            topFilterBar.currentFilter = topFilterBar.filter2
                            topFilterBar.filterSelected(topFilterBar.filter2)
                        }
                    }

                    Button {
                        text: topFilterBar.label3
                        width: units.gu(11)
                        height: units.gu(4)
                        property bool isHighlighted: topFilterBar.currentFilter === topFilterBar.filter3
                        color: isHighlighted ? "#f78787" : '#b4dff0'

                        onClicked: {
                            topFilterBar.currentFilter = topFilterBar.filter3
                            topFilterBar.filterSelected(topFilterBar.filter3)
                        }
                    }

                    Button {
                        text: topFilterBar.label6
                        width: units.gu(11)
                        height: units.gu(4)
                        property bool isHighlighted: topFilterBar.currentFilter === topFilterBar.filter6
                        color: isHighlighted ? "#f78787" : "#b4dff0"

                        onClicked: {
                            topFilterBar.currentFilter = topFilterBar.filter6
                            topFilterBar.filterSelected(topFilterBar.filter6)
                        }
                    }
                }
            }
        }

        TextField {
            id: searchField
            visible: showSearch
            placeholderText: i18n.tr("Search workouts...")
            width: parent.width - units.gu(2)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.margins: units.gu(1)
            onTextChanged: refreshModel(text)
        }

        ListView {
            width: parent.width
            height: parent.height - topFilterBar.height - (searchField.visible ? searchField.height + units.gu(2) : 0)
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