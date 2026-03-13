import QtQuick 2.7
import Lomiri.Components 1.3

Page {
    header: PageHeader {
        title: "Settings"

         StyleHints {
            foregroundColor: "white"
             backgroundColor: '#f78787'
            dividerColor: LomiriColors.slate
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: units.gu(2)

        Label {
            text: "Settings Page"
        }
    }
}