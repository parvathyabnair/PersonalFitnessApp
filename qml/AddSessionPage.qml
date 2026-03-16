import QtQuick 2.7
import Lomiri.Components 1.3
//import QtQuick.Window 2.2
import QtQml.Models 2.3
//import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0
//mport "components"

Page {
    header: PageHeader {
        title: "Add Session"
        trailingActionBar.numberOfSlots: 1

         StyleHints {
            foregroundColor: "white"
             backgroundColor: '#f78787'
            dividerColor: LomiriColors.slate
        }
            trailingActionBar.actions: [
        
              
               Action {
    iconName: "add"
    text: i18n.tr("Add Session")

    onTriggered: {
        pageStack.push(Qt.resolvedUrl("SessionCreatePage.qml"))
    }
}]
    }


 

Column {
        anchors.centerIn: parent
        spacing: units.gu(2)

        Label {
            text: i18n.tr("Add workout session here")
        }
    }
}