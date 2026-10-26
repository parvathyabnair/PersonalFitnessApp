import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtQuick.Layouts 1.3
import QtMultimedia 5.8
import Lomiri.Content 1.3
import "database.js" as DB

Page {
    id: vaultPage
    anchors.fill: parent
    property var pageLayout
    property int filterSessionId: -1
    property string activeFilter: "all" // "all", "photo", "video"
    property var mediaList: []

    // ContentHub active transfer tracking
    property var activeTransfer: null
    property string pendingExercise: "Squats"
    property string pendingMediaType: "photo"

    Rectangle {
        anchors.fill: parent
        color: root.isDarkMode ? "#121214" : "#F8F9FA"
        z: -1
    }

    function refreshMedia() {
        mediaList = DB.getMediaVaultItems(filterSessionId, activeFilter)
    }

    function savePhotoToVault(filePath, exercise) {
        var ex = exercise || pendingExercise || "Progress Photo"
        var nowStr = Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm")
        var fileName = "progress_" + Date.now() + ".jpg"
        DB.insertMediaVaultItem(
            vaultPage.filterSessionId,
            ex,
            ex + " Photo",
            "photo",
            fileName,
            filePath,
            nowStr,
            0,
            "Captured with phone camera"
        )
        refreshMedia()
    }

    function saveVideoToVault(filePath, exercise, duration) {
        var ex = exercise || pendingExercise || "Form Check"
        var nowStr = Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm")
        var fileName = "form_check_" + Date.now() + ".mp4"
        DB.insertMediaVaultItem(
            vaultPage.filterSessionId,
            ex,
            ex + " Video",
            "video",
            fileName,
            filePath,
            nowStr,
            duration || 1,
            "Form check video recording"
        )
        refreshMedia()
    }

    function openContentPicker(type, exercise, mediaType) {
        pendingExercise = exercise || "Squats"
        pendingMediaType = mediaType || (type === ContentType.Videos ? "video" : "photo")
        peerPicker.contentType = type
        peerPickerOverlay.visible = true
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
                iconName: "camera-photo"
                text: i18n.tr("Snap Photo")
                onTriggered: {
                    openContentPicker(ContentType.Pictures, "Progress Photo", "photo")
                }
            },
            Action {
                iconName: "media-record"
                text: i18n.tr("Record Video")
                onTriggered: {
                    openContentPicker(ContentType.Videos, "Squats", "video")
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

            // PRIMARY CAMERA & CAPTURE ACTION BUTTONS
            Column {
                width: parent.width
                spacing: units.gu(1)

                Row {
                    width: parent.width
                    spacing: units.gu(1.5)

                    Button {
                        text: i18n.tr("📸 Snap Photo")
                        color: root.primaryColor
                        width: (parent.width - units.gu(1.5)) / 2
                        height: units.gu(4.8)
                        onClicked: {
                            openContentPicker(ContentType.Pictures, "Progress Photo", "photo")
                        }
                    }

                    Button {
                        text: i18n.tr("🎥 Record Form Check")
                        color: root.accentOrange
                        width: (parent.width - units.gu(1.5)) / 2
                        height: units.gu(4.8)
                        onClicked: {
                            openContentPicker(ContentType.Videos, "Squats", "video")
                        }
                    }
                }

                Button {
                    text: i18n.tr("⚡ In-App Viewfinder & Alignment Grid")
                    color: root.cardBorderColor
                    width: parent.width
                    height: units.gu(4.2)
                    onClicked: {
                        viewfinderLoader.active = true
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
                        anchors.margins: units.gu(1.5)
                        spacing: units.gu(1.5)

                        // Media Thumbnail Box
                        Rectangle {
                            width: units.gu(10)
                            height: units.gu(10)
                            radius: units.dp(8)
                            color: root.isDarkMode ? "#2D3139" : "#E5E7EB"
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: {
                                    if (!modelData.file_url || modelData.file_url === "") return Qt.resolvedUrl("../assets/download.png")
                                    var u = String(modelData.file_url)
                                    return (u.indexOf("://") !== -1) ? u : ("file://" + u)
                                }
                                fillMode: Image.PreserveAspectCrop
                                visible: modelData.media_type === "photo"
                            }

                            // Video placeholder / icon
                            Item {
                                anchors.fill: parent
                                visible: modelData.media_type === "video"

                                Rectangle {
                                    anchors.fill: parent
                                    color: "#18191B"
                                }

                                Label {
                                    text: "🎥"
                                    font.pixelSize: units.gu(3)
                                    anchors.centerIn: parent
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: units.gu(0.5)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    height: units.gu(2)
                                    width: durLabel.width + units.gu(1)
                                    radius: units.dp(4)
                                    color: Qt.rgba(0, 0, 0, 0.75)

                                    Label {
                                        id: durLabel
                                        anchors.centerIn: parent
                                        text: modelData.duration + "s"
                                        color: "white"
                                        font.pixelSize: units.gu(1)
                                    }
                                }
                            }
                        }

                        // Info Column
                        Column {
                            Layout.fillWidth: true
                            spacing: units.gu(0.4)

                            Row {
                                spacing: units.gu(0.8)

                                Rectangle {
                                    height: units.gu(2.4)
                                    width: typeLabel.width + units.gu(1.4)
                                    radius: height / 2
                                    color: modelData.media_type === "video" ? "#EF4444" : root.primaryColor

                                    Label {
                                        id: typeLabel
                                        anchors.centerIn: parent
                                        text: modelData.media_type === "video" ? i18n.tr("VIDEO") : i18n.tr("PHOTO")
                                        color: "white"
                                        font.bold: true
                                        font.pixelSize: units.gu(0.9)
                                    }
                                }

                                Label {
                                    text: modelData.exercise || "Workout"
                                    color: root.textSecondaryColor
                                    font.pixelSize: units.gu(1.2)
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Label {
                                text: modelData.title || i18n.tr("Media Item")
                                font.bold: true
                                font.pixelSize: units.gu(1.4)
                                color: root.textPrimaryColor
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Label {
                                text: "📅 " + (modelData.date || "")
                                font.pixelSize: units.gu(1.1)
                                color: root.textSecondaryColor
                            }

                            Label {
                                text: modelData.notes || i18n.tr("Sandboxed private media")
                                font.pixelSize: units.gu(1.1)
                                color: root.textSecondaryColor
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        // Actions Column
                        Column {
                            spacing: units.gu(1)

                            Button {
                                iconName: "delete"
                                color: "transparent"
                                width: units.gu(3.8)
                                height: units.gu(3.8)
                                onClicked: {
                                    DB.deleteMediaVaultItem(modelData.id)
                                    vaultPage.refreshMedia()
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

    // CONTENT HUB SYSTEM CAMERA & GALLERY PICKER OVERLAY
    Rectangle {
        id: peerPickerOverlay
        anchors.fill: parent
        color: root.isDarkMode ? "#121214" : "#F8F9FA"
        visible: false
        z: 920

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                height: units.gu(6.5)
                color: root.primaryColor

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: units.gu(1.5)
                    anchors.rightMargin: units.gu(1.5)

                    Label {
                        text: (peerPicker.contentType === ContentType.Videos) ?
                              i18n.tr("Select Camera or Video App") :
                              i18n.tr("Select Camera or Gallery App")
                        color: "white"
                        font.bold: true
                        font.pixelSize: units.gu(1.5)
                        Layout.fillWidth: true
                    }

                    Button {
                        text: i18n.tr("Close")
                        height: units.gu(4)
                        color: LomiriColors.slate
                        onClicked: {
                            peerPickerOverlay.visible = false
                        }
                    }
                }
            }

            ContentPeerPicker {
                id: peerPicker
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentType: ContentType.Pictures
                handler: ContentHandler.Source

                onPeerSelected: {
                    peer.selectionType = ContentTransfer.Single
                    vaultPage.activeTransfer = peer.request()
                    stateChangeConnection.target = vaultPage.activeTransfer
                    peerPickerOverlay.visible = false
                }

                onCancelPressed: {
                    peerPickerOverlay.visible = false
                }
            }
        }
    }

    Connections {
        id: stateChangeConnection
        target: null
        onStateChanged: {
            if (vaultPage.activeTransfer && vaultPage.activeTransfer.state === ContentTransfer.Charged) {
                var items = vaultPage.activeTransfer.items
                for (var i = 0; i < items.length; i++) {
                    var u = String(items[i].url)
                    var path = u.replace("file://", "")
                    if (vaultPage.pendingMediaType === "video") {
                        saveVideoToVault(path, vaultPage.pendingExercise, 5)
                    } else {
                        savePhotoToVault(path, vaultPage.pendingExercise)
                    }
                }
                vaultPage.activeTransfer = null
            }
        }
    }

    // SAFE LAZY-LOADED IN-APP VIEWFINDER & POSTURE GRID
    Loader {
        id: viewfinderLoader
        anchors.fill: parent
        active: false
        z: 900
        sourceComponent: viewfinderComponent
    }

    Component {
        id: viewfinderComponent

        Rectangle {
            id: viewfinderRoot
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.95)

            property string captureType: "photo" // "photo" or "video"
            property string targetExercise: "Squats"
            property int recordingSeconds: 0
            property bool isRecording: false
            property bool cameraFailed: false

            Timer {
                id: recordTimer
                interval: 1000
                repeat: true
                running: viewfinderRoot.isRecording
                onTriggered: {
                    viewfinderRoot.recordingSeconds++
                }
            }

            Camera {
                id: realCamera
                cameraState: Camera.ActiveState
                captureMode: viewfinderRoot.captureType === "video" ? Camera.CaptureVideo : Camera.CaptureStillImage
                position: Camera.BackFace

                imageCapture {
                    onImageSaved: {
                        console.log("Real camera photo captured:", path)
                        vaultPage.savePhotoToVault(path, viewfinderRoot.targetExercise)
                        viewfinderLoader.active = false
                    }
                    onCaptureFailed: {
                        console.log("Image capture error:", message)
                    }
                }

                videoRecorder {
                    onRecorderStateChanged: {
                        if (realCamera.videoRecorder.recorderState === CameraRecorder.StoppedState) {
                            vaultPage.saveVideoToVault(realCamera.videoRecorder.actualLocation || "", viewfinderRoot.targetExercise, Math.max(1, viewfinderRoot.recordingSeconds))
                            viewfinderLoader.active = false
                        }
                    }
                }

                onError: {
                    console.log("Camera hardware error:", errorString)
                    viewfinderRoot.cameraFailed = true
                }
            }

            // Top Control Bar
            Rectangle {
                id: topBar
                width: parent.width
                height: units.gu(6.5)
                anchors.top: parent.top
                color: "#18191B"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: units.gu(1.5)
                    anchors.rightMargin: units.gu(1.5)

                    Rectangle {
                        width: units.gu(4)
                        height: units.gu(4)
                        radius: units.dp(6)
                        color: "#2D3139"

                        Label {
                            text: "✕"
                            color: "white"
                            font.bold: true
                            font.pixelSize: units.gu(1.6)
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                viewfinderLoader.active = false
                            }
                        }
                    }

                    Label {
                        text: viewfinderRoot.captureType === "video" ? i18n.tr("Form-Check Video Capture") : i18n.tr("Progress Photo Snap")
                        color: "white"
                        font.bold: true
                        font.pixelSize: units.gu(1.6)
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Rectangle {
                        width: units.gu(7.5)
                        height: units.gu(3.8)
                        radius: units.dp(6)
                        color: "#2D3139"

                        Label {
                            text: realCamera.position === Camera.BackFace ? "🔄 Front" : "🔄 Back"
                            color: "white"
                            font.pixelSize: units.gu(1.2)
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                realCamera.position = (realCamera.position === Camera.BackFace) ? Camera.FrontFace : Camera.BackFace
                            }
                        }
                    }
                }
            }

            // Central Viewfinder Box
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

                // VideoOutput for Camera Stream
                VideoOutput {
                    id: cameraView
                    anchors.fill: parent
                    source: realCamera
                    autoOrientation: true
                    fillMode: VideoOutput.PreserveAspectCrop
                }

                // Fallback Card if Camera Hardware is Unavailable or in Error
                Rectangle {
                    anchors.fill: parent
                    color: "#18191B"
                    visible: realCamera.cameraStatus !== Camera.ActiveStatus || viewfinderRoot.cameraFailed
                    z: 5

                    Column {
                        anchors.centerIn: parent
                        width: parent.width * 0.85
                        spacing: units.gu(1.5)

                        Label {
                            text: "📷"
                            font.pixelSize: units.gu(4)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Label {
                            text: i18n.tr("Camera Feed Inactive")
                            color: "white"
                            font.bold: true
                            font.pixelSize: units.gu(1.6)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Label {
                            text: i18n.tr("Direct preview is not available on this device configuration. Tap below to use the System Camera.")
                            color: "#AAAAAA"
                            font.pixelSize: units.gu(1.2)
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }

                        Button {
                            text: i18n.tr("Open System Camera")
                            color: root.primaryColor
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: units.gu(4.5)
                            onClicked: {
                                viewfinderLoader.active = false
                                vaultPage.openContentPicker(viewfinderRoot.captureType === "video" ? ContentType.Videos : ContentType.Pictures, viewfinderRoot.targetExercise, viewfinderRoot.captureType)
                            }
                        }
                    }
                }

                // Posture Alignment Guidelines
                Item {
                    anchors.fill: parent
                    visible: realCamera.cameraStatus === Camera.ActiveStatus && !viewfinderRoot.cameraFailed

                    // Vertical center line
                    Rectangle {
                        width: units.dp(1.5)
                        height: parent.height
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "#38BDF8"
                        opacity: 0.6
                    }

                    // Horizontal shoulder guide
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

                // Exercise Badge
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
                        text: "🏋️ " + viewfinderRoot.targetExercise
                        color: "white"
                        font.bold: true
                        font.pixelSize: units.gu(1.3)
                    }
                }

                // Recording Indicator
                Rectangle {
                    visible: viewfinderRoot.isRecording
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: units.gu(1.5)
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: units.gu(3.6)
                    width: units.gu(14)
                    radius: height / 2
                    color: Qt.rgba(0, 0, 0, 0.85)

                    Row {
                        anchors.centerIn: parent
                        spacing: units.gu(0.8)

                        Rectangle {
                            width: units.gu(1.2)
                            height: units.gu(1.2)
                            radius: width / 2
                            color: "#EF4444"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Label {
                            text: {
                                var mins = Math.floor(viewfinderRoot.recordingSeconds / 60)
                                var secs = viewfinderRoot.recordingSeconds % 60
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

            // Exercise Selection Pills
            Row {
                anchors.bottom: bottomBar.top
                anchors.bottomMargin: units.gu(1)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: units.gu(1)

                Repeater {
                    model: ["Squats", "Bench Press", "Deadlift", "Progress Photo"]
                    delegate: Rectangle {
                        height: units.gu(3.2)
                        width: pillTxt.width + units.gu(2)
                        radius: height / 2
                        color: viewfinderRoot.targetExercise === modelData ? root.primaryColor : "#2D3139"

                        Label {
                            id: pillTxt
                            anchors.centerIn: parent
                            text: modelData
                            color: "white"
                            font.bold: viewfinderRoot.targetExercise === modelData
                            font.pixelSize: units.gu(1.1)
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: viewfinderRoot.targetExercise = modelData
                        }
                    }
                }
            }

            // Bottom Shutter & Controls
            Rectangle {
                id: bottomBar
                width: parent.width
                height: units.gu(11)
                anchors.bottom: parent.bottom
                color: "#18191B"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: units.gu(2.5)
                    anchors.rightMargin: units.gu(2.5)

                    // Mode switch
                    Button {
                        text: viewfinderRoot.captureType === "photo" ? "🎥 Video Mode" : "📸 Photo Mode"
                        color: root.cardBorderColor
                        height: units.gu(4.5)
                        onClicked: {
                            viewfinderRoot.captureType = (viewfinderRoot.captureType === "photo") ? "video" : "photo"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Shutter Trigger Button
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
                            radius: viewfinderRoot.isRecording ? units.dp(8) : (width / 2)
                            color: viewfinderRoot.captureType === "video" ? "#EF4444" : "white"
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (viewfinderRoot.captureType === "photo") {
                                    if (realCamera.cameraStatus === Camera.ActiveStatus && !viewfinderRoot.cameraFailed) {
                                        realCamera.imageCapture.capture()
                                    } else {
                                        viewfinderLoader.active = false
                                        vaultPage.openContentPicker(ContentType.Pictures, viewfinderRoot.targetExercise, "photo")
                                    }
                                } else {
                                    if (!viewfinderRoot.isRecording) {
                                        viewfinderRoot.isRecording = true
                                        viewfinderRoot.recordingSeconds = 0
                                        if (realCamera.cameraStatus === Camera.ActiveStatus && !viewfinderRoot.cameraFailed) {
                                            realCamera.videoRecorder.record()
                                        }
                                    } else {
                                        viewfinderRoot.isRecording = false
                                        if (realCamera.cameraStatus === Camera.ActiveStatus && realCamera.videoRecorder.recorderState === CameraRecorder.RecordingState) {
                                            realCamera.videoRecorder.stop()
                                        } else {
                                            vaultPage.saveVideoToVault("", viewfinderRoot.targetExercise, Math.max(1, viewfinderRoot.recordingSeconds))
                                            viewfinderLoader.active = false
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: viewfinderRoot.captureType === "video" ?
                              (viewfinderRoot.isRecording ? i18n.tr("Tap to STOP") : i18n.tr("Tap to RECORD")) :
                              i18n.tr("Tap to SNAP")
                        color: "white"
                        font.pixelSize: units.gu(1.1)
                    }
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

            Rectangle {
                width: units.gu(4)
                height: units.gu(4)
                radius: units.dp(6)
                color: "#373A40"

                Label {
                    text: "✕"
                    color: "white"
                    font.bold: true
                    font.pixelSize: units.gu(1.6)
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: previewModal.closePreview()
                }
            }
        }

        // Content
        Item {
            anchors.centerIn: parent
            width: parent.width - units.gu(4)
            height: parent.height - units.gu(16)

            Image {
                anchors.fill: parent
                source: {
                    if (!previewModal.currentItem || !previewModal.currentItem.file_url || previewModal.currentItem.file_url === "") return Qt.resolvedUrl("../assets/download.png")
                    var u = String(previewModal.currentItem.file_url)
                    return (u.indexOf("://") !== -1) ? u : ("file://" + u)
                }
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
