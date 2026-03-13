import QtQuick 2.7
import Lomiri.Components 1.3

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
    text: "Add Session"

    onTriggered: {
        pageStack.push(Qt.resolvedUrl("SessionCreatePage.qml"))
    }
}]
    }

    Column {
        anchors.centerIn: parent
        spacing: units.gu(2)

        Label {
            text: "Add workout session here"
        }
    }
}