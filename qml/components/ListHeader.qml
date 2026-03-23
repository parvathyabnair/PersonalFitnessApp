import QtQuick 2.7
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

Rectangle {
    id: topFilterBar
    width: parent ? parent.width : Screen.width
    height: showSearchBox ? units.gu(11) : units.gu(6)
    color: "#ffffff"

    // Exposed properties for customization
    property string label1: "Today"
    property string label2: "Next Week"
    property string label3: "Next Month"
    property string label4: "Later"
    property string label5: "OverDue"
    property string label6: "All"
    property string label7: "Done"

    property string filter1: "today"
    property string filter2: "next_week"
    property string filter3: "next_month"
    property string filter4: "later"
    property string filter5: "overdue"
    property string filter6: "all"
    property string filter7: "done"

    property string currentFilter: filter1  // Default filter

    signal filterSelected(string filterKey)  // Custom signal

    // Flickable to make tabs scrollable horizontally
    Flickable {
        id: flickable
        width: parent.width
        height: units.gu(6)
        contentWidth: rowLayout.width
        contentHeight: rowLayout.height
        clip: true
        flickableDirection: Flickable.HorizontalFlick

        Row {
            id: rowLayout
            spacing: 0
            anchors.left: parent.left
            anchors.top: parent.top

            // Repeated Button structure for each tab
            Button {
                text: topFilterBar.label1
                height: units.gu(6)
                width: units.gu(12)
                property bool isHighlighted: topFilterBar.currentFilter === topFilterBar.filter1
                background: Rectangle {
                    color: parent.isHighlighted ? "#F2EDE8" : "#E0E0E0"
                    border.color: parent.isHighlighted ? "#F2EDE8" : "#CCCCCC"
                    border.width: 1
                }
                contentItem: Text {
                    text: parent.text
                    color: parent.isHighlighted ? "#FF6B35" : "#8C7059"
                    font.bold: parent.isHighlighted
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    topFilterBar.currentFilter = topFilterBar.filter1;
                    topFilterBar.filterSelected(topFilterBar.filter1);
                }
            }

            // (Repeat similar Button blocks for label2 - label7)
            // Each follows the same structure, only differing in filter key
        }
    }

    // Displaying current filter description
    Rectangle {
        width: parent.width * 0.9
        height: units.gu(5)
        radius: 8
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: flickable.bottom
        anchors.topMargin: units.gu(2)
        Label {
            anchors.centerIn: parent
            text: {
                if (currentFilter === filter1) return "This is Today Tab";
                if (currentFilter === filter2) return "This is Next Week Tab";
                if (currentFilter === filter3) return "This is Next Month Tab";
                if (currentFilter === filter4) return "This is Later Tab";
                if (currentFilter === filter5) return "This is OverDue Tab";
                if (currentFilter === filter6) return "This is All Tab";
                if (currentFilter === filter7) return "This is Done Tab";
                return "";
            }
            color: "#333"
            font.pixelSize: units.gu(2)
        }
    }
}