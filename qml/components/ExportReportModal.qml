import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Content 1.3
import QtQuick.Layouts 1.3
import "../utilities/ReportGenerator.js" as ReportGen
import "../utilities/Formatters.js" as Formatters

Item {
    id: exportModal
    anchors.fill: parent
    visible: opacity > 0
    opacity: 0
    z: 1000

    property color primaryColor: (typeof root !== "undefined" && root.primaryColor) ? root.primaryColor : "#fc5d5d"
    property color secondaryColor: (typeof root !== "undefined" && root.secondaryColor) ? root.secondaryColor : "#79cff2"
    property color cardBgColor: (typeof root !== "undefined" && root.cardBgColor) ? root.cardBgColor : "#FFFFFF"
    property color cardBorderColor: (typeof root !== "undefined" && root.cardBorderColor) ? root.cardBorderColor : "#E9ECEF"
    property color textPrimaryColor: (typeof root !== "undefined" && root.textPrimaryColor) ? root.textPrimaryColor : "#1A1B1E"
    property color textSecondaryColor: (typeof root !== "undefined" && root.textSecondaryColor) ? root.textSecondaryColor : "#6C757D"
    property bool isDarkMode: (typeof root !== "undefined" && root.isDarkMode) ? root.isDarkMode : false

    property string selectedFormat: "pdf" // "pdf" or "csv"
    property string selectedTimeframe: "all" // "all", "month", "week"
    property bool isGenerated: false
    property var lastResult: null
    property bool showPeerPicker: false
    property var previewData: null

    Behavior on opacity {
        NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
    }

    function openModal() {
        isGenerated = false
        lastResult = null
        showPeerPicker = false
        refreshPreview()
        opacity = 1
    }

    function closeModal() {
        opacity = 0
        showPeerPicker = false
    }

    function refreshPreview() {
        var todayWater = (typeof root !== "undefined") ? root.todayWaterMl : 0
        var targetWater = (typeof root !== "undefined") ? root.targetWaterMl : 2000
        previewData = ReportGen.buildReportData(selectedTimeframe, todayWater, targetWater)
    }

    // Backdrop overlay
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.65)

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (!exportModal.showPeerPicker) {
                    exportModal.closeModal()
                }
            }
        }
    }

    // Modal Card
    Rectangle {
        id: cardContainer
        width: Math.min(parent.width - units.gu(4), units.gu(48))
        height: Math.min(modalContentCol.height + units.gu(4), parent.height - units.gu(6))
        anchors.centerIn: parent
        radius: units.dp(16)
        color: exportModal.cardBgColor
        border.color: exportModal.cardBorderColor
        border.width: units.dp(1)
        clip: true

        MouseArea {
            anchors.fill: parent
            // Prevent clicks from dismissing modal
        }

      

        Flickable {
            id: modalFlickable
            anchors.fill: parent
            anchors.margins: units.gu(2)
            contentHeight: modalContentCol.height
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: modalContentCol
                width: parent.width
                spacing: units.gu(1.6)

                // Header Row
                RowLayout {
                    width: parent.width

                   

                    Column {
                        Layout.fillWidth: true
                        spacing: units.dp(2)

                        Label {
                            text: i18n.tr("Export Fitness Report")
                            font.bold: true
                            font.pixelSize: units.gu(1.8)
                            color: exportModal.textPrimaryColor
                        }

                        Label {
                            text: i18n.tr("Generate a formatted summary of your workouts & metrics")
                            font.pixelSize: units.gu(1.1)
                            color: exportModal.textSecondaryColor
                        }
                    }

                    Button {
                        text: "✕"
                        width: units.gu(4)
                        height: units.gu(4)
                        color: exportModal.cardBorderColor
                        onClicked: exportModal.closeModal()
                    }
                }

                Rectangle {
                    width: parent.width
                    height: units.dp(1)
                    color: exportModal.cardBorderColor
                }

                // Normal Config View (when not yet generated)
                Column {
                    width: parent.width
                    spacing: units.gu(1.4)
                    visible: !exportModal.isGenerated

                    // SECTION 1: Format Selector
                    Column {
                        width: parent.width
                        spacing: units.gu(0.8)

                        Label {
                            text: i18n.tr("1. Choose Document Format")
                            font.bold: true
                            font.pixelSize: units.gu(1.2)
                            color: exportModal.textPrimaryColor
                        }

                        RowLayout {
                            width: parent.width
                            spacing: units.gu(1)

                            // PDF Chip Button
                            Rectangle {
                                Layout.fillWidth: true
                                height: units.gu(4.6)
                                radius: units.dp(10)
                                color: exportModal.selectedFormat === "pdf" ? 
                                       Qt.rgba(exportModal.primaryColor.r, exportModal.primaryColor.g, exportModal.primaryColor.b, 0.15) : 
                                       exportModal.cardBgColor
                                border.color: exportModal.selectedFormat === "pdf" ? exportModal.primaryColor : exportModal.cardBorderColor
                                border.width: units.dp(exportModal.selectedFormat === "pdf" ? 2 : 1)

                                Row {
                                    anchors.centerIn: parent
                                    spacing: units.gu(0.8)
                                
                                    Label {
                                        text: i18n.tr("PDF Document")
                                        font.bold: exportModal.selectedFormat === "pdf"
                                        color: exportModal.selectedFormat === "pdf" ? exportModal.primaryColor : exportModal.textPrimaryColor
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        exportModal.selectedFormat = "pdf"
                                    }
                                }
                            }

                            // CSV Chip Button
                            Rectangle {
                                Layout.fillWidth: true
                                height: units.gu(4.6)
                                radius: units.dp(10)
                                color: exportModal.selectedFormat === "csv" ? 
                                       Qt.rgba(exportModal.secondaryColor.r, exportModal.secondaryColor.g, exportModal.secondaryColor.b, 0.20) : 
                                       exportModal.cardBgColor
                                border.color: exportModal.selectedFormat === "csv" ? exportModal.secondaryColor : exportModal.cardBorderColor
                                border.width: units.dp(exportModal.selectedFormat === "csv" ? 2 : 1)

                                Row {
                                    anchors.centerIn: parent
                                    spacing: units.gu(0.8)
                                   
                                    Label {
                                        text: i18n.tr("CSV Spreadsheet")
                                        font.bold: exportModal.selectedFormat === "csv"
                                        color: exportModal.selectedFormat === "csv" ? (exportModal.isDarkMode ? "#FFFFFF" : "#0A5C80") : exportModal.textPrimaryColor
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        exportModal.selectedFormat = "csv"
                                    }
                                }
                            }
                        }
                    }

                    // SECTION 2: Timeframe Selector
                    Column {
                        width: parent.width
                        spacing: units.gu(0.8)

                        Label {
                            text: i18n.tr("2. Select Date Range")
                            font.bold: true
                            font.pixelSize: units.gu(1.2)
                            color: exportModal.textPrimaryColor
                        }

                        RowLayout {
                            width: parent.width
                            spacing: units.gu(0.8)

                            Repeater {
                                model: [
                                    { label: i18n.tr("All Time"), value: "all" },
                                    { label: i18n.tr("This Month"), value: "month" },
                                    { label: i18n.tr("This Week"), value: "week" }
                                ]

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: units.gu(3.8)
                                    radius: units.dp(8)
                                    color: exportModal.selectedTimeframe === modelData.value ? 
                                           exportModal.primaryColor : 
                                           exportModal.cardBorderColor

                                    Label {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        font.bold: exportModal.selectedTimeframe === modelData.value
                                        font.pixelSize: units.gu(1.1)
                                        color: exportModal.selectedTimeframe === modelData.value ? "white" : exportModal.textPrimaryColor
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            exportModal.selectedTimeframe = modelData.value
                                            exportModal.refreshPreview()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // SECTION 3: Live Preview Info Card
                    Rectangle {
                        width: parent.width
                        height: previewCol.height + units.gu(1.8)
                        radius: units.dp(10)
                        color: exportModal.isDarkMode ? "#1C1D21" : "#F8F9FA"
                        border.color: exportModal.cardBorderColor
                        border.width: units.dp(1)

                        Column {
                            id: previewCol
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: units.gu(1)
                            spacing: units.gu(0.6)

                            Label {
                                text: i18n.tr("Report Contents Preview")
                                font.bold: true
                                font.pixelSize: units.gu(1.1)
                                color: exportModal.textSecondaryColor
                            }

                            RowLayout {
                                width: parent.width

                                Column {
                                    Layout.fillWidth: true
                                    Label {
                                        text: exportModal.previewData ? (exportModal.previewData.stats.total_sessions + " " + i18n.tr("Workouts")) : "-"
                                        font.bold: true
                                        font.pixelSize: units.gu(1.4)
                                        color: exportModal.primaryColor
                                    }
                                    Label {
                                        text: i18n.tr("Total Sessions")
                                        font.pixelSize: units.gu(0.9)
                                        color: exportModal.textSecondaryColor
                                    }
                                }

                                Column {
                                    Layout.fillWidth: true
                                    Label {
                                        text: exportModal.previewData ? exportModal.previewData.stats.total_hours : "-"
                                        font.bold: true
                                        font.pixelSize: units.gu(1.4)
                                        color: exportModal.textPrimaryColor
                                    }
                                    Label {
                                        text: i18n.tr("Workout Time")
                                        font.pixelSize: units.gu(0.9)
                                        color: exportModal.textSecondaryColor
                                    }
                                }

                                Column {
                                    Layout.fillWidth: true
                                    Label {
                                        text: exportModal.previewData ? (exportModal.previewData.stats.total_calories + " kcal") : "-"
                                        font.bold: true
                                        font.pixelSize: units.gu(1.4)
                                        color: exportModal.primaryColor
                                    }
                                    Label {
                                        text: i18n.tr("Burned Calories")
                                        font.pixelSize: units.gu(0.9)
                                        color: exportModal.textSecondaryColor
                                    }
                                }
                            }
                        }
                    }

                    // Generate Button
                    Button {
                        text: i18n.tr("Generate & Export Report")
                        width: parent.width
                        height: units.gu(4.8)
                        color: exportModal.primaryColor

                        onClicked: {
                            var todayWater = (typeof root !== "undefined") ? root.todayWaterMl : 0
                            var targetWater = (typeof root !== "undefined") ? root.targetWaterMl : 2000
                            var res = ReportGen.exportReport(exportModal.selectedFormat, exportModal.selectedTimeframe, todayWater, targetWater)
                            exportModal.lastResult = res
                            exportModal.isGenerated = true
                        }
                    }
                }

                // Success View (once generated)
                Column {
                    width: parent.width
                    spacing: units.gu(1.4)
                    visible: exportModal.isGenerated

                    // Success Card
                    Rectangle {
                        width: parent.width
                        height: successCol.height + units.gu(2)
                        radius: units.dp(12)
                        color: exportModal.isDarkMode ? "#1B2E24" : "#F0FDF4"
                        border.color: "#34D399"
                        border.width: units.dp(1)

                        Column {
                            id: successCol
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: units.gu(1.2)
                            spacing: units.gu(0.8)

                            Row {
                                spacing: units.gu(0.8)
                                
                                Label {
                                    text: i18n.tr("Report Generated Successfully!")
                                    font.bold: true
                                    font.pixelSize: units.gu(1.3)
                                    color: "#10B981"
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: units.gu(3.2)
                                radius: units.dp(6)
                                color: exportModal.isDarkMode ? "#25262B" : "#FFFFFF"
                                border.color: exportModal.cardBorderColor

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: units.gu(0.6)

                                    Label {
                                        text: exportModal.lastResult ? exportModal.lastResult.fileName : ""
                                        font.bold: true
                                        font.pixelSize: units.gu(1.1)
                                        color: exportModal.textPrimaryColor
                                        Layout.fillWidth: true
                                        elide: Text.ElideMiddle
                                    }

                                    Rectangle {
                                        width: units.gu(4.5)
                                        height: units.gu(2.2)
                                        radius: units.dp(4)
                                        color: exportModal.secondaryColor
                                        Label {
                                            anchors.centerIn: parent
                                            text: (exportModal.selectedFormat === "pdf" ? "PDF" : "CSV")
                                            font.bold: true
                                            font.pixelSize: units.gu(0.9)
                                            color: "#1A1B1E"
                                        }
                                    }
                                }
                            }

                            Label {
                                text: exportModal.lastResult ? (i18n.tr("File Size: ") + Math.round(exportModal.lastResult.fileSize / 1024) + " KB ") : ""
                                font.pixelSize: units.gu(0.95)
                                color: exportModal.textSecondaryColor
                                wrapMode: Text.WrapAnywhere
                                width: parent.width
                            }
                        }
                    }

                    // Actions
                    Button {
                        text: i18n.tr("Save/Share Report")
                        width: parent.width
                        height: units.gu(4.8)
                        color: exportModal.secondaryColor

                        onClicked: {
                            exportModal.showPeerPicker = true
                        }
                    }

                    RowLayout {
                        width: parent.width
                        spacing: units.gu(1)

                        Button {
                            Layout.fillWidth: true
                            text: i18n.tr("Generate Another")
                            color: exportModal.cardBorderColor
                            height: units.gu(4.2)
                            onClicked: {
                                exportModal.isGenerated = false
                                exportModal.refreshPreview()
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: i18n.tr("Done")
                            color: exportModal.primaryColor
                            height: units.gu(4.2)
                            onClicked: {
                                exportModal.closeModal()
                            }
                        }
                    }
                }
            }
        }
    }

    // ContentHub Item
    ContentItem {
        id: exportContentItem
        url: exportModal.lastResult ? exportModal.lastResult.fileUrl : ""
        name: exportModal.lastResult ? exportModal.lastResult.fileName : "Fitness_Report.pdf"
    }

    // ContentPeerPicker Overlay for Sharing
    Rectangle {
        id: peerPickerOverlay
        anchors.fill: parent
        color: exportModal.cardBgColor
        visible: exportModal.showPeerPicker
        z: 1100

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: units.gu(1.5)
            spacing: units.gu(1)

            RowLayout {
                Layout.fillWidth: true

                Label {
                    text: i18n.tr("Choose Destination / App")
                    font.bold: true
                    font.pixelSize: units.gu(1.6)
                    color: exportModal.textPrimaryColor
                    Layout.fillWidth: true
                }

                Button {
                    text: i18n.tr("Cancel")
                    color: exportModal.cardBorderColor
                    onClicked: {
                        exportModal.showPeerPicker = false
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: units.dp(1)
                color: exportModal.cardBorderColor
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ContentPeerPicker {
                    anchors.fill: parent
                    contentType: ContentType.Documents
                    handler: ContentHandler.Share

                    onPeerSelected: {
                        peer.selectionType = ContentTransfer.Single
                        var transfer = peer.request()
                        transfer.items = [ exportContentItem ]
                        transfer.state = ContentTransfer.Charged
                        exportModal.showPeerPicker = false
                    }

                    onCancelPressed: {
                        exportModal.showPeerPicker = false
                    }
                }
            }
        }
    }
}
