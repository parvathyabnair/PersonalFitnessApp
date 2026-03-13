import QtQuick 2.4
import Lomiri.Components 1.3

Item {
    id: root
    width: units.gu(12)
    height: units.gu(12)
    
    Image {
        id: logo
        anchors.fill: parent
        source: Qt.resolvedUrl("../assets/download.png")
        fillMode: Image.PreserveAspectFit
        
        // Fallback if logo doesn't exist
        Rectangle {
            anchors.fill: parent
            color: '#f78787' // Ubuntu orange
            radius: width / 2
            visible: logo.status === Image.Error || logo.status === Image.Null
            
            Label {
                anchors.centerIn: parent
                text: "TA"
                font.pixelSize: units.gu(6)
                color: "white"
                font.bold: true
            }
        }
    }
}





















