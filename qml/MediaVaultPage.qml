import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtQuick.Layouts 1.3
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

    function savePhotoToVault(filePath, exercise, customTitle, notes) {
        var ex = exercise || pendingExercise || "Progress Photo"
        var t = customTitle ? customTitle.trim() : (ex.toLowerCase().indexOf("photo") !== -1 ? ex : (ex + " Photo"))
        if (t === "") t = "Progress Photo"
        var nowStr = Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm")
        var fileName = "progress_" + Date.now() + ".jpg"
        DB.insertMediaVaultItem(
            vaultPage.filterSessionId,
            ex,
            t,
            "photo",
            fileName,
            filePath,
            nowStr,
            0,
            notes || "Captured with phone camera"
        )
        refreshMedia()
    }

    function saveVideoToVault(filePath, exercise, duration, customTitle, notes) {
        var ex = exercise || pendingExercise || "Form Check"
        var t = customTitle ? customTitle.trim() : (ex.toLowerCase().indexOf("video") !== -1 ? ex : (ex + " Form Check"))
        if (t === "") t = "Form Check Video"
        var nowStr = Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm")
        var fileName = "form_check_" + Date.now() + ".mp4"
        DB.insertMediaVaultItem(
            vaultPage.filterSessionId,
            ex,
            t,
            "video",
            fileName,
            filePath,
            nowStr,
            duration || 1,
            notes || "Form check video recording"
        )
        refreshMedia()
    }

    function openContentPicker(type, exercise, mediaType) {
        pendingExercise = exercise || (type === ContentType.Videos ? "Form Check" : "Progress Photo")
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
                iconName: "camera-symbolic"
                iconSource: Qt.resolvedUrl("../assets/camera_icon.svg")
                text: i18n.tr("Snap Photo")
                onTriggered: {
                    openContentPicker(ContentType.Pictures, vaultPage.pendingExercise || "Progress Photo", "photo")
                }
            },
            Action {
                iconName: "camcorder"
                iconSource: Qt.resolvedUrl("../assets/video_icon.svg")
                text: i18n.tr("Record Video")
                onTriggered: {
                    openContentPicker(ContentType.Videos, vaultPage.pendingExercise || "Form Check", "video")
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
            Row {
                width: parent.width
                spacing: units.gu(1.5)

                Button {
                    text: i18n.tr("📸 Snap Photo")
                    color: root.primaryColor
                    width: (parent.width - units.gu(1.5)) / 2
                    height: units.gu(4.8)
                    onClicked: {
                        openContentPicker(ContentType.Pictures, vaultPage.pendingExercise || "Progress Photo", "photo")
                    }
                }

                Button {
                    text: i18n.tr("🎥 Record Video")
                    color: root.accentOrange
                    width: (parent.width - units.gu(1.5)) / 2
                    height: units.gu(4.8)
                    onClicked: {
                        openContentPicker(ContentType.Videos, vaultPage.pendingExercise || "Form Check", "video")
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
                            spacing: units.gu(0.8)

                            Button {
                                iconName: "edit"
                                color: "transparent"
                                width: units.gu(3.8)
                                height: units.gu(3.8)
                                onClicked: {
                                    saveMediaModal.openForEdit(modelData)
                                }
                            }

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

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ContentPeerPicker {
                    id: peerPicker
                    anchors.fill: parent
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
                    saveMediaModal.openForNewMedia(path, vaultPage.pendingMediaType, vaultPage.pendingExercise)
                }
                vaultPage.activeTransfer = null
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
                    text: "✏️"
                    font.pixelSize: units.gu(1.3)
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var itm = previewModal.currentItem
                        previewModal.closePreview()
                        if (itm) saveMediaModal.openForEdit(itm)
                    }
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

    // SAVE / EDIT MEDIA NAMING MODAL
    Rectangle {
        id: saveMediaModal
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.75)
        visible: false
        z: 960

        property bool isEditMode: false
        property int editItemId: -1
        property string mediaPath: ""
        property string mediaType: "photo" // "photo" or "video"
        property int mediaDuration: 5

        function openForNewMedia(path, type, defaultExercise) {
            isEditMode = false
            editItemId = -1
            mediaPath = path || ""
            mediaType = type || "photo"
            mediaDuration = 5

            var ex = defaultExercise || (mediaType === "video" ? "Form Check" : "Progress Photo")
            exerciseInput.text = ex
            var defaultTitle = (mediaType === "video") ? 
                (ex === "Form Check" ? "Form Check Video" : (ex + " Form Check")) : 
                (ex === "Progress Photo" ? "Progress Photo" : (ex + " Photo"))
            titleInput.text = defaultTitle
            notesInput.text = ""
            visible = true
            titleInput.forceActiveFocus()
        }

        function openForEdit(item) {
            if (!item) return
            isEditMode = true
            editItemId = item.id
            mediaPath = item.file_url || ""
            mediaType = item.media_type || "photo"
            mediaDuration = item.duration || 0
            exerciseInput.text = item.exercise || ""
            titleInput.text = item.title || ""
            notesInput.text = item.notes || ""
            visible = true
            titleInput.forceActiveFocus()
        }

        function close() {
            visible = false
            Qt.inputMethod.hide()
        }

        function confirmSave() {
            var chosenTitle = titleInput.text.trim()
            if (chosenTitle === "") {
                chosenTitle = (mediaType === "video") ? "Form Check Video" : "Progress Photo"
            }
            var chosenExercise = exerciseInput.text.trim()
            if (chosenExercise === "") {
                chosenExercise = (mediaType === "video") ? "Form Check" : "Progress Photo"
            }
            var chosenNotes = notesInput.text.trim()

            if (isEditMode && editItemId !== -1) {
                DB.updateMediaVaultItem(editItemId, chosenTitle, chosenExercise, chosenNotes)
                vaultPage.refreshMedia()
            } else {
                if (mediaType === "video") {
                    saveVideoToVault(mediaPath, chosenExercise, mediaDuration, chosenTitle, chosenNotes)
                } else {
                    savePhotoToVault(mediaPath, chosenExercise, chosenTitle, chosenNotes)
                }
            }
            close()
        }

        MouseArea {
            anchors.fill: parent
            onClicked: saveMediaModal.close()
        }

        Rectangle {
            id: modalBox
            anchors.centerIn: parent
            width: Math.min(units.gu(42), parent.width - units.gu(3))
            height: Math.min(units.gu(58), parent.height - units.gu(4))
            radius: units.dp(16)
            color: root.cardBgColor
            border.color: root.cardBorderColor
            border.width: units.dp(1)
            clip: true

            MouseArea {
                anchors.fill: parent
                onClicked: {} // Block clicks inside from dismissing modal
            }

            Flickable {
                anchors.fill: parent
                anchors.margins: units.gu(2)
                contentWidth: width
                contentHeight: modalContentCol.height + units.gu(2)
                clip: true

                Column {
                    id: modalContentCol
                    width: parent.width
                    spacing: units.gu(1.5)

                    // Header row
                    RowLayout {
                        width: parent.width

                        Label {
                            text: saveMediaModal.isEditMode ? 
                                  i18n.tr("✏️ Edit Media Details") : 
                                  (saveMediaModal.mediaType === "video" ? i18n.tr("🎥 Save Form Check Video") : i18n.tr("📸 Save Progress Photo"))
                            font.bold: true
                            font.pixelSize: units.gu(1.6)
                            color: root.textPrimaryColor
                            Layout.fillWidth: true
                        }

                        Button {
                            text: "✕"
                            width: units.gu(3.6)
                            height: units.gu(3.6)
                            color: root.cardBorderColor
                            onClicked: saveMediaModal.close()
                        }
                    }

                    // Media preview thumbnail
                    Rectangle {
                        width: parent.width
                        height: units.gu(14)
                        radius: units.dp(10)
                        color: root.isDarkMode ? "#1A1D20" : "#E5E7EB"
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: {
                                if (!saveMediaModal.mediaPath || saveMediaModal.mediaPath === "") return ""
                                var u = String(saveMediaModal.mediaPath)
                                return (u.indexOf("://") !== -1) ? u : ("file://" + u)
                            }
                            fillMode: Image.PreserveAspectCrop
                            visible: saveMediaModal.mediaType === "photo" && saveMediaModal.mediaPath !== ""
                        }

                        Column {
                            anchors.centerIn: parent
                            visible: saveMediaModal.mediaType === "video"
                            spacing: units.gu(0.5)

                            Label {
                                text: "🎥"
                                font.pixelSize: units.gu(3.5)
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Label {
                                text: i18n.tr("Private Video Recording")
                                font.bold: true
                                font.pixelSize: units.gu(1.2)
                                color: root.textPrimaryColor
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    // Title / Name Field
                    Column {
                        width: parent.width
                        spacing: units.gu(0.5)

                        Label {
                            text: (saveMediaModal.mediaType === "video") ? 
                                  i18n.tr("Video Name / Title *") : 
                                  i18n.tr("Photo Name / Title *")
                            font.bold: true
                            font.pixelSize: units.gu(1.3)
                            color: root.textPrimaryColor
                        }

                        TextField {
                            id: titleInput
                            width: parent.width
                            placeholderText: (saveMediaModal.mediaType === "video") ? 
                                i18n.tr("e.g. Squat Form Check, Deadlift PR") : 
                                i18n.tr("e.g. Front Double Bicep, Morning Check-in")
                        }
                    }

                    // Exercise Tag Field
                    Column {
                        width: parent.width
                        spacing: units.gu(0.5)

                        Label {
                            text: i18n.tr("Exercise / Category")
                            font.bold: true
                            font.pixelSize: units.gu(1.3)
                            color: root.textPrimaryColor
                        }

                        TextField {
                            id: exerciseInput
                            width: parent.width
                            placeholderText: i18n.tr("e.g. Squats, Bench Press, Progress Photo")
                        }

                        // Quick selection chips
                        Row {
                            spacing: units.gu(0.8)
                            width: parent.width

                            Repeater {
                                model: ["Squats", "Bench Press", "Deadlift", "Progress Photo"]
                                delegate: Rectangle {
                                    height: units.gu(2.8)
                                    width: chipTxt.width + units.gu(1.6)
                                    radius: height / 2
                                    color: exerciseInput.text === modelData ? root.primaryColor : root.cardBorderColor

                                    Label {
                                        id: chipTxt
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: exerciseInput.text === modelData ? "white" : root.textPrimaryColor
                                        font.pixelSize: units.gu(1.0)
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            exerciseInput.text = modelData
                                            if (titleInput.text === "" || titleInput.text === "Progress Photo" || titleInput.text.indexOf("Form Check") !== -1 || titleInput.text.indexOf("Photo") !== -1) {
                                                if (saveMediaModal.mediaType === "video") {
                                                    titleInput.text = modelData + " Form Check"
                                                } else {
                                                    titleInput.text = (modelData === "Progress Photo") ? "Progress Photo" : (modelData + " Photo")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Optional Notes Field
                    Column {
                        width: parent.width
                        spacing: units.gu(0.5)

                        Label {
                            text: i18n.tr("Notes (Optional)")
                            font.pixelSize: units.gu(1.2)
                            color: root.textSecondaryColor
                        }

                        TextField {
                            id: notesInput
                            width: parent.width
                            placeholderText: i18n.tr("e.g. Felt heavy, depth was parallel")
                        }
                    }

                    // Action Buttons (Save & Cancel)
                    Row {
                        width: parent.width
                        spacing: units.gu(1.2)

                        Button {
                            text: i18n.tr("Cancel")
                            color: root.cardBorderColor
                            width: (parent.width - units.gu(1.2)) / 2
                            height: units.gu(4.5)
                            onClicked: saveMediaModal.close()
                        }

                        Button {
                            text: saveMediaModal.isEditMode ? i18n.tr("Save Changes") : i18n.tr("Save to Vault")
                            color: root.primaryColor
                            width: (parent.width - units.gu(1.2)) / 2
                            height: units.gu(4.5)
                            onClicked: saveMediaModal.confirmSave()
                        }
                    }
                }
            }
        }
    }
}
