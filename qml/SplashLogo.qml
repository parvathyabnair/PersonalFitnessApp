import QtQuick 2.4
import Lomiri.Components 1.3

Item {
    id: root
    width: units.gu(12)
    height: units.gu(12)
    
    Image {
        id: logo
        anchors.fill: parent
        source: Qt.resolvedUrl("../assets/logo.png")
        sourceSize.width: units.gu(12)
        sourceSize.height: units.gu(12)
        fillMode: Image.PreserveAspectFit
        
        // Fallback if logo doesn't exist
        Rectangle {
            anchors.fill: parent
            color: '#FF5252'
            radius: units.dp(24)
            visible: logo.status === Image.Error || logo.status === Image.Null
            
            Label {
                anchors.centerIn: parent
                text: "PFA"
                font.pixelSize: units.gu(3.5)
                color: "white"
                font.bold: true
            }
        }
    }
}





















