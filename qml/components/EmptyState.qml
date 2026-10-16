import QtQuick 2.7
import Lomiri.Components 1.3

Column {
    id: root
    property string title: ""
    property string message: i18n.tr("You haven't logged a workout today. Let's get moving!")
    property string imageSource: (typeof theme !== "undefined" && theme.name === "Ubuntu.Components.Themes.SuruDark") ? 
                                 Qt.resolvedUrl("../../assets/person_darkmode.png") : 
                                 Qt.resolvedUrl("../../assets/person_whitemode.png")
    
    width: Math.min(parent ? parent.width * 0.85 : units.gu(35), units.gu(36))
    spacing: units.gu(1.5)
    
    Image {
        source: root.imageSource
        width: Math.min(units.gu(16), root.width * 0.6)
        height: width
        anchors.horizontalCenter: parent.horizontalCenter
        fillMode: Image.PreserveAspectFit
        opacity: 0.95
    }

    Label {
        text: root.title
        visible: root.title.length > 0
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        font.pixelSize: units.gu(2.2)
        font.bold: true
        color: (typeof root.textPrimaryColor !== "undefined") ? root.textPrimaryColor : (theme.name === "Ubuntu.Components.Themes.SuruDark" ? "#FFFFFF" : "#1A1B1E")
    }
    
    Label {
        text: root.message
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        font.pixelSize: units.gu(1.6)
        color: (typeof root.textSecondaryColor !== "undefined") ? root.textSecondaryColor : "#888888"
        lineHeight: 1.3
    }
}
