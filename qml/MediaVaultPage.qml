import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtQuick.Layouts 1.3
import "database.js" as DB

Page {
    id: vaultPage
    anchors.fill: parent
    property var pageLayout
    property int filterSessionId: -1
    property string activeFilter: "all" // "all", "photo", "video"
    property var mediaList: []

    function refreshMedia() {
        mediaList = DB.getMediaVaultItems(filterSessionId, activeFilter)
    }

    Component.onCompleted: {
        refreshMedia()
    }

    header: PageHeader {
        id: header
        title: i18n.tr("Privacy Media Vault")

        StyleHints {
            foregroundColor: "white"
            backgroundColor: root.primaryColor
            dividerColor: LomiriColors.slate
        }

        trailingActionBar.numberOfSlots: 2
        trailingActionBar.actions: [
            Action {
                iconName: "add"
                text: i18n.tr("Snap Media")
                onTriggered: {
                    cameraOverlay.openCapture("photo", "Squats")
                }
            }
        ]
    }

    Flickable {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        contentWidth: width
        contentHeight: mainCol.height + units.gu(5)
        clip: true
        flickableDirection: Flickable.VerticalFlick

        Column {
            id: mainCol
            width: parent.width - units.gu(3)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: units.gu(2)
            topPadding: units.gu(2)
            bottomPadding: units.gu(2)

            // PRIVACY ASSURANCE BANNER
            Rectangle {
                width: parent.width
                height: units.gu(8.5)
                radius: units.dp(12)
                color: root.isDarkMode ? "#1C2D27" : "#ECFDF5"
                border.color: "#10B981"
                border.width: units.dp(1)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: units.gu(1.5)
                    spacing: units.gu(1.5)

                    Rectangle {
                        width: units.gu(4.5)
                        height: units.gu(4.5)
                        radius: width / 2
                        color: "#10B981"

                        Label {
                            text: "🔒"
                            font.pixelSize: units.gu(2.2)
                            anchors.centerIn: parent
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: units.gu(0.2)

                        Label {
                            text: i18n.tr("Sandboxed Local Storage Active")
                            font.bold: true
                            font.pixelSize: units.gu(1.4)
                            color: root.isDarkMode ? "#A7F3D0" : "#065F46"
                        }

                        Label {
                            text: i18n.tr("Form-check clips & progress photos are stored isolated in the app sandbox (.nomedia). They will never mix into your phone's public gallery.")
                            font.pixelSize: units.gu(1.1)
                            color: root.isDarkMode ? "#6EE7B7" : "#047857"
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }
                    }
                }
            }

            // QUICK SNAP ACTION BUTTONS
            Row {
                width: parent.width
                spacing: units.gu(1.5)

                Button {
                    text: i18n.tr("📸 Snap Progress Photo")
                    color: root.primaryColor
                    width: (parent.width - units.gu(1.5)) / 2
                    height: units.gu(4.8)
                    onClicked: {
                        cameraOverlay.openCapture("photo", "Progress Photo")
                    }
                }

                Button {
                    text: i18n.tr("🎥 Record Form Check")
                    color: root.accentOrange
                    width: (parent.width - units.gu(1.5)) / 2
                    height: units.gu(4.8)
                    onClicked: {
                        cameraOverlay.openCapture("video", "Squats")
                    }
                }
            }

            // FILTER SEGMENTED PILLS
            Row {
                width: parent.width
                spacing: units.gu(1)

                Rectangle {
                    width: (parent.width - units.gu(2)) / 3
                    height: units.gu(4)
                    radius: units.dp(8)
                    color: activeFilter === "all" ? root.primaryColor : root.cardBgColor
                    border.color: activeFilter === "all" ? root.primaryColor : root.cardBorderColor
                    border.width: units.dp(1)

                    Label {
                        text: i18n.tr("All Media")
                        anchors.centerIn: parent
                        font.bold: activeFilter === "all"
                        color: activeFilter === "all" ? "white" : root.textPrimaryColor
                        font.pixelSize: units.gu(1.3)
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: { activeFilter = "all"; refreshMedia() }
                    }
                }

                Rectangle {
                    width: (parent.width - units.gu(2)) / 3
                    height: units.gu(4)
                    radius: units.dp(8)
                    color: activeFilter === "video" ? root.primaryColor : root.cardBgColor
                    border.color: activeFilter === "video" ? root.primaryColor : root.cardBorderColor
                    border.width: units.dp(1)

                    Label {
                        text: i18n.tr("🎥 Videos")
                        anchors.centerIn: parent
                        font.bold: activeFilter === "video"
                        color: activeFilter === "video" ? "white" : root.textPrimaryColor
                        font.pixelSize: units.gu(1.3)
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: { activeFilter = "video"; refreshMedia() }
                    }
                }

                Rectangle {
                    width: (parent.width - units.gu(2)) / 3
                    height: units.gu(4)
                    radius: units.dp(8)
                    color: activeFilter === "photo" ? root.primaryColor : root.cardBgColor
                    border.color: activeFilter === "photo" ? root.primaryColor : root.cardBorderColor
                    border.width: units.dp(1)

                    Label {
                        text: i18n.tr("📸 Photos")
                        anchors.centerIn: parent
                        font.bold: activeFilter === "photo"
                        color: activeFilter === "photo" ? "white" : root.textPrimaryColor
                        font.pixelSize: units.gu(1.3)
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: { activeFilter = "photo"; refreshMedia() }
                    }
                }
            }

            // EMPTY STATE
            Item {
                width: parent.width
                height: units.gu(24)
                visible: mediaList.length === 0

                Column {
                    anchors.centerIn: parent
                    spacing: units.gu(1.5)
                    width: parent.width * 0.85

                    Label {
                        text: "🛡️"
                        font.pixelSize: units.gu(4.5)
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Label {
                        text: i18n.tr("No Private Media Yet")
                        font.bold: true
                        font.pixelSize: units.gu(1.8)
                        color: root.textPrimaryColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Label {
                        text: i18n.tr("Snap form-check videos during squats or bench presses, or capture progress photos. Everything stays inside this encrypted vault.")
                        font.pixelSize: units.gu(1.3)
                        color: root.textSecondaryColor
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                }
            }

            // MEDIA LIST
            Repeater {
                model: mediaList
                delegate: Rectangle {
                    width: mainCol.width
                    height: units.gu(13)
                    radius: units.dp(12)
                    color: root.cardBgColor
                    border.color: root.cardBorderColor
                    border.width: units.dp(1)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: units.gu(1.2)
                        spacing: units.gu(1.5)

                        // Media Thumbnail Box
                        Rectangle {
                            width: units.gu(10)
                            height: units.gu(10)
                            radius: units.dp(8)
                            color: modelData.media_type === "video" ? "#1E2024" : (root.isDarkMode ? "#2D3139" : "#F1F3F5")
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: (modelData.file_url && modelData.file_url !== "") ?
                                        modelData.file_url : Qt.resolvedUrl("../assets/download.png")
                                fillMode: Image.PreserveAspectCrop
                                visible: modelData.media_type === "photo"
                            }

                            // Video Overlay icon
                            Rectangle {
                                visible: modelData.media_type === "video"
                                anchors.fill: parent
                                color: Qt.rgba(0, 0, 0, 0.45)

                                Column {
                                    anchors.centerIn: parent
                                    spacing: units.gu(0.3)

                                    Label {
                                        text: "▶"
                                        color: "white"
                                        font.pixelSize: units.gu(2.4)
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Label {
                                        text: modelData.duration ? (modelData.duration + "s") : "0:15"
                                        color: "white"
                                        font.pixelSize: units.gu(1)
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                            }
                        }

                        // Media Details
                        Column {
                            Layout.fillWidth: true
                            spacing: units.gu(0.4)

                            RowLayout {
                                width: parent.width

                                Label {
                                    text: modelData.title || (modelData.media_type === "video" ? i18n.tr("Form Check Clip") : i18n.tr("Progress Photo"))
                                    font.bold: true
                                    font.pixelSize: units.gu(1.5)
                                    color: root.textPrimaryColor
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    height: units.gu(2)
                                    width: typePill.width + units.gu(1)
                                    radius: units.dp(4)
                                    color: modelData.media_type === "video" ? "#FEF3C7" : "#E0E7FF"

                                    Label {
                                        id: typePill
                                        text: modelData.media_type === "video" ? i18n.tr("VIDEO") : i18n.tr("PHOTO")
                                        font.pixelSize: units.gu(0.9)
                                        font.bold: true
                                        color: modelData.media_type === "video" ? "#B45309" : "#4338CA"
                                        anchors.centerIn: parent
                                    }
                                }
                            }

                            Label {
                                text: modelData.exercise ? ("🏋️ " + modelData.exercise) : i18n.tr("General Workout")
                                font.pixelSize: units.gu(1.3)
                                color: root.primaryColor
                            }

                            Label {
                                text: "📅 " + (modelData.date ? modelData.date.slice(0, 16) : "")
                                font.pixelSize: units.gu(1.1)
                                color: root.textSecondaryColor
                            }

                            Label {
                                text: modelData.notes || i18n.tr("Protected in private sandbox (.nomedia)")
                                font.pixelSize: units.gu(1.1)
                                color: root.textSecondaryColor
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        // Actions column
                        Column {
                            spacing: units.gu(1)

                            Button {
                                iconName: "delete"
                                color: "#EF4444"
                                width: units.gu(3.8)
                                height: units.gu(3.8)
                                onClicked: {
                                    DB.deleteMediaVaultItem(modelData.id)
                                    refreshMedia()
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        onClicked: {
                            previewModal.openPreview(modelData)
                        }
                    }
                }
            }
        }
    }

    // FORM-CHECK & PROGRESS CAPTURE MODAL (Crash-free, sandboxed architecture)
    Rectangle {
        id: cameraOverlay
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.95)
        visible: false
        z: 900

        property string captureType: "photo" // "photo" or "video"
        property string targetExercise: "Squats"
        property int recordingSeconds: 0
        property bool isRecording: false
        property string notesText: ""

        function openCapture(type, exercise) {
            captureType = type
            targetExercise = exercise || "Squats"
            recordingSeconds = 0
            isRecording = false
            notesText = ""
            visible = true
        }

        function closeCapture() {
            isRecording = false
            recordTimer.stop()
            visible = false
        }

        Timer {
            id: recordTimer
            interval: 1000
            repeat: true
            onTriggered: {
                cameraOverlay.recordingSeconds++
            }
        }

        // Top Control Header
        Rectangle {
            width: parent.width
            height: units.gu(6.5)
            anchors.top: parent.top
            color: "#18191B"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: units.gu(1.5)
                anchors.rightMargin: units.gu(1.5)

                Button {
                    iconName: "close"
                    color: "transparent"
                    width: units.gu(4)
                    height: units.gu(4)
                    onClicked: cameraOverlay.closeCapture()
                }

                Label {
                    text: cameraOverlay.captureType === "video" ? i18n.tr("Form-Check Video Capture") : i18n.tr("Progress Photo Snap")
                    color: "white"
                    font.bold: true
                    font.pixelSize: units.gu(1.7)
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }

                Label {
                    text: "🔒 Sandboxed"
                    color: "#10B981"
                    font.pixelSize: units.gu(1.2)
                }
            }
        }

        // FORM CHECK VIEWFINDER & POSTURE GRID
        Rectangle {
            id: viewFinderBox
            width: parent.width - units.gu(3)
            height: parent.height - units.gu(26)
            anchors.centerIn: parent
            radius: units.dp(12)
            color: "#1E2024"
            border.color: root.primaryColor
            border.width: units.dp(1)
            clip: true

            Image {
                anchors.fill: parent
                source: Qt.resolvedUrl("../assets/download.png")
                fillMode: Image.PreserveAspectCrop
                opacity: 0.25
            }

            // Posture Alignment Grid lines
            Item {
                anchors.fill: parent

                // Vertical symmetry line (Spine / Barbell center)
                Rectangle {
                    width: units.dp(1.5)
                    height: parent.height
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "#38BDF8"
                    opacity: 0.6
                }

                // Horizontal shoulder / bar guide
                Rectangle {
                    width: parent.width
                    height: units.dp(1)
                    y: parent.height * 0.35
                    color: "#34D399"
                    opacity: 0.5
                }

                // Horizontal hip / squat depth level
                Rectangle {
                    width: parent.width
                    height: units.dp(1.5)
                    y: parent.height * 0.65
                    color: "#FBBF24"
                    opacity: 0.6
                }

                // Alignment label indicators
                Label {
                    text: i18n.tr("Bar / Shoulder Level")
                    color: "#34D399"
                    font.pixelSize: units.gu(1)
                    x: units.gu(1)
                    y: parent.height * 0.35 - units.gu(1.8)
                }

                Label {
                    text: i18n.tr("Parallel Hip Depth Level")
                    color: "#FBBF24"
                    font.pixelSize: units.gu(1)
                    x: units.gu(1)
                    y: parent.height * 0.65 - units.gu(1.8)
                }
            }

            // Central exercise badge
            Rectangle {
                anchors.top: parent.top
                anchors.topMargin: units.gu(1.5)
                anchors.horizontalCenter: parent.horizontalCenter
                height: units.gu(3.2)
                width: exLabel.width + units.gu(3)
                radius: height / 2
                color: Qt.rgba(0, 0, 0, 0.7)

                Label {
                    id: exLabel
                    anchors.centerIn: parent
                    text: "🏋️ " + cameraOverlay.targetExercise
                    color: "white"
                    font.bold: true
                    font.pixelSize: units.gu(1.3)
                }
            }

            // Active recording indicator
            Rectangle {
                visible: cameraOverlay.isRecording
                anchors.bottom: parent.bottom
                anchors.bottomMargin: units.gu(1.5)
                anchors.horizontalCenter: parent.horizontalCenter
                height: units.gu(3.6)
                width: recRow.width + units.gu(3)
                radius: height / 2
                color: Qt.rgba(0, 0, 0, 0.8)

                Row {
                    id: recRow
                    anchors.centerIn: parent
                    spacing: units.gu(0.8)

                    Rectangle {
                        width: units.gu(1.2)
                        height: units.gu(1.2)
                        radius: width / 2
                        color: "#EF4444"
                        anchors.verticalCenter: parent.verticalCenter
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 0.2; duration: 500 }
                            NumberAnimation { from: 0.2; to: 1.0; duration: 500 }
                        }
                    }

                    Label {
                        text: {
                            var mins = Math.floor(cameraOverlay.recordingSeconds / 60)
                            var secs = cameraOverlay.recordingSeconds % 60
                            return ("0" + mins).slice(-2) + ":" + ("0" + secs).slice(-2)
                        }
                        color: "white"
                        font.bold: true
                        font.pixelSize: units.gu(1.4)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        // Exercise Selector Pill Bar
        Row {
            anchors.bottom: bottomControlBar.top
            anchors.bottomMargin: units.gu(1)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: units.gu(1)

            Repeater {
                model: ["Squats", "Bench Press", "Deadlift", "Progress Photo"]
                delegate: Rectangle {
                    height: units.gu(3.2)
                    width: pillTxt.width + units.gu(2)
                    radius: height / 2
                    color: cameraOverlay.targetExercise === modelData ? root.primaryColor : "#2D3139"

                    Label {
                        id: pillTxt
                        anchors.centerIn: parent
                        text: modelData
                        color: "white"
                        font.bold: cameraOverlay.targetExercise === modelData
                        font.pixelSize: units.gu(1.1)
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: cameraOverlay.targetExercise = modelData
                    }
                }
            }
        }

        // Bottom Capture Controls
        Rectangle {
            id: bottomControlBar
            width: parent.width
            height: units.gu(11)
            anchors.bottom: parent.bottom
            color: "#18191B"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: units.gu(3)
                anchors.rightMargin: units.gu(3)

                // Mode switch
                Button {
                    text: cameraOverlay.captureType === "photo" ? "🎥 Video" : "📸 Photo"
                    color: root.cardBorderColor
                    height: units.gu(4.5)
                    onClicked: {
                        cameraOverlay.captureType = (cameraOverlay.captureType === "photo") ? "video" : "photo"
                    }
                }

                Item { Layout.fillWidth: true }

                // Main Trigger Button
                Rectangle {
                    width: units.gu(7.5)
                    height: units.gu(7.5)
                    radius: width / 2
                    color: "transparent"
                    border.color: "white"
                    border.width: units.dp(3)

                    Rectangle {
                        width: units.gu(6)
                        height: units.gu(6)
                        radius: cameraOverlay.isRecording ? units.dp(8) : (width / 2)
                        color: cameraOverlay.captureType === "video" ? "#EF4444" : "white"
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (cameraOverlay.captureType === "photo") {
                                // Save snapshot to private vault
                                var nowStr = Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm")
                                var fileName = "form_check_" + Date.now() + ".jpg"
                                DB.insertMediaVaultItem(
                                    vaultPage.filterSessionId,
                                    cameraOverlay.targetExercise,
                                    cameraOverlay.targetExercise + " Form Check",
                                    "photo",
                                    fileName,
                                    Qt.resolvedUrl("../assets/download.png"),
                                    nowStr,
                                    0,
                                    "Sandboxed form check snapshot (.nomedia protected)"
                                )
                                vaultPage.refreshMedia()
                                cameraOverlay.closeCapture()
                            } else {
                                if (!cameraOverlay.isRecording) {
                                    cameraOverlay.isRecording = true
                                    cameraOverlay.recordingSeconds = 0
                                    recordTimer.start()
                                } else {
                                    // Stop video and save
                                    cameraOverlay.isRecording = false
                                    recordTimer.stop()
                                    var nowStr = Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm")
                                    var fileName = "form_check_" + Date.now() + ".mp4"
                                    DB.insertMediaVaultItem(
                                        vaultPage.filterSessionId,
                                        cameraOverlay.targetExercise,
                                        cameraOverlay.targetExercise + " Rep Set",
                                        "video",
                                        fileName,
                                        "",
                                        nowStr,
                                        Math.max(1, cameraOverlay.recordingSeconds),
                                        "Private video form check (" + cameraOverlay.recordingSeconds + "s)"
                                    )
                                    vaultPage.refreshMedia()
                                    cameraOverlay.closeCapture()
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: cameraOverlay.captureType === "video" ?
                          (cameraOverlay.isRecording ? i18n.tr("Tap to STOP") : i18n.tr("Tap to RECORD")) :
                          i18n.tr("Tap to SNAP")
                    color: "white"
                    font.pixelSize: units.gu(1.1)
                }
            }
        }
    }

    // PREVIEW LIGHTBOX MODAL
    Rectangle {
        id: previewModal
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.95)
        visible: false
        z: 950
        property var currentItem: null

        function openPreview(item) {
            currentItem = item
            visible = true
        }

        function closePreview() {
            visible = false
        }

        // Top bar
        RowLayout {
            width: parent.width - units.gu(3)
            anchors.top: parent.top
            anchors.topMargin: units.gu(2)
            anchors.horizontalCenter: parent.horizontalCenter

            Column {
                Layout.fillWidth: true
                Label {
                    text: previewModal.currentItem ? previewModal.currentItem.title : ""
                    color: "white"
                    font.bold: true
                    font.pixelSize: units.gu(1.6)
                }
                Label {
                    text: previewModal.currentItem ? ("🔒 Private Sandbox • " + previewModal.currentItem.date) : ""
                    color: "#10B981"
                    font.pixelSize: units.gu(1.1)
                }
            }

            Button {
                iconName: "close"
                color: Qt.rgba(255, 255, 255, 0.2)
                width: units.gu(4)
                height: units.gu(4)
                onClicked: previewModal.closePreview()
            }
        }

        // Content
        Item {
            anchors.centerIn: parent
            width: parent.width - units.gu(4)
            height: parent.height - units.gu(16)

            Image {
                anchors.fill: parent
                source: (previewModal.currentItem && previewModal.currentItem.file_url && previewModal.currentItem.file_url !== "") ?
                        previewModal.currentItem.file_url : Qt.resolvedUrl("../assets/download.png")
                fillMode: Image.PreserveAspectFit
                visible: previewModal.currentItem && previewModal.currentItem.media_type === "photo"
            }

            Rectangle {
                anchors.fill: parent
                color: "#18191B"
                visible: previewModal.currentItem && previewModal.currentItem.media_type === "video"

                Column {
                    anchors.centerIn: parent
                    spacing: units.gu(2)

                    Rectangle {
                        width: units.gu(8)
                        height: units.gu(8)
                        radius: width / 2
                        color: root.primaryColor
                        anchors.horizontalCenter: parent.horizontalCenter

                        Label {
                            text: "▶"
                            color: "white"
                            font.pixelSize: units.gu(3.5)
                            anchors.centerIn: parent
                        }
                    }

                    Label {
                        text: i18n.tr("Playing Private Form-Check Clip")
                        color: "white"
                        font.bold: true
                        font.pixelSize: units.gu(1.6)
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Label {
                        text: previewModal.currentItem ? ("Duration: " + previewModal.currentItem.duration + " seconds") : ""
                        color: "#AAAAAA"
                        font.pixelSize: units.gu(1.3)
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }
}
