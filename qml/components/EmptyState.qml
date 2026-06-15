import QtQuick 2.7
import Lomiri.Components 1.3

Column {
    id: root
    property string message: i18n.tr("You haven't logged a workout today. Let's get moving!")
    property string imageSource: theme.name === "Ubuntu.Components.Themes.SuruDark" ? "../../assets/person_darkmode.png" : "../../assets/person_whitemode.png"
    
    anchors.centerIn: parent
    width: parent.width * 0.8
    spacing: units.gu(3)
    
    Image {
        source: root.imageSource
        width: units.gu(20)
        height: units.gu(20)
        anchors.horizontalCenter: parent.horizontalCenter
        fillMode: Image.PreserveAspectFit
    }
    
    Label {
        text: root.message
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        font.pixelSize: units.gu(1.8)
        color: "#f78787"
        font.bold: true
        lineHeight: 1.2
    }
}
