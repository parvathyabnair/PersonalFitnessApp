import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3

Page {
    id: wearablesPage
    anchors.fill: parent
    property var pageLayout

    header: PageHeader {
        id: header
        title: i18n.tr("Wearables & Sensors")

        StyleHints {
            foregroundColor: "white"
            backgroundColor: root.primaryColor
            dividerColor: LomiriColors.slate
        }
    }

    Flickable {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        contentWidth: width
        contentHeight: contentCol.height + units.gu(5)
        clip: true
        flickableDirection: Flickable.VerticalFlick

        Column {
            id: contentCol
            width: parent.width - units.gu(3)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: units.gu(2)
            topPadding: units.gu(2)
            bottomPadding: units.gu(2)

            // DEVICE CONNECTION STATUS CARD
            Rectangle {
                width: parent.width
                height: units.gu(16)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)

                Column {
                    anchors.fill: parent
                    anchors.margins: units.gu(1.5)
                    spacing: units.gu(1)

                    RowLayout {
                        width: parent.width

                        Rectangle {
                            width: units.gu(5.5)
                            height: units.gu(5.5)
                            radius: units.dp(10)
                            color: root.isDarkMode ? "#373A40" : "#F1F3F5"

                            Label {
                                text: "⌚"
                                font.pixelSize: units.gu(3)
                                anchors.centerIn: parent
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: units.gu(0.2)

                            Row {
                                spacing: units.gu(1)

                                Label {
                                    text: root.backendBridge.deviceName
                                    font.bold: true
                                    font.pixelSize: units.gu(1.8)
                                    color: root.textPrimaryColor
                                }

                                Rectangle {
                                    width: statusText.width + units.gu(1.5)
                                    height: units.gu(2.4)
                                    radius: height / 2
                                    color: root.backendBridge.connected ? "#ECFDF5" : "#FEF2F2"
                                    border.color: root.backendBridge.connected ? "#10B981" : "#EF4444"
                                    border.width: units.dp(1)
                                    anchors.verticalCenter: parent.verticalCenter

                                    Label {
                                        id: statusText
                                        text: root.backendBridge.connected ? i18n.tr("Connected") : i18n.tr("Disconnected")
                                        font.pixelSize: units.gu(1.1)
                                        font.bold: true
                                        color: root.backendBridge.connected ? "#059669" : "#DC2626"
                                        anchors.centerIn: parent
                                    }
                                }
                            }

                            Label {
                                text: i18n.tr("MAC: ") + root.backendBridge.deviceMac + " • " + root.backendBridge.firmwareVersion
                                font.pixelSize: units.gu(1.2)
                                color: root.textSecondaryColor
                            }

                            Label {
                                text: i18n.tr("Protocol: Gadgetbridge Xiaomi Band 9 BLE")
                                font.pixelSize: units.gu(1.1)
                                color: root.accentBlue
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: units.dp(1)
                        color: root.cardBorderColor
                    }

                    RowLayout {
                        width: parent.width

                        Label {
                            text: i18n.tr("Battery Level: ") + root.backendBridge.batteryLevel + "%"
                            font.pixelSize: units.gu(1.3)
                            color: root.textSecondaryColor
                        }

                        Item { Layout.fillWidth: true }

                        Button {
                            text: root.backendBridge.connected ? i18n.tr("Disconnect") : i18n.tr("Connect")
                            color: root.backendBridge.connected ? root.cardBorderColor : root.primaryColor
                            height: units.gu(3.8)
                            onClicked: {
                                if (root.backendBridge.connected) {
                                    root.backendBridge.disconnectDevice()
                                } else {
                                    root.backendBridge.connectDevice(root.backendBridge.deviceMac, "")
                                }
                            }
                        }
                    }
                }
            }

            // LIVE HEART RATE MONITOR CARD
            Rectangle {
                width: parent.width
                height: units.gu(17)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)

                Column {
                    anchors.fill: parent
                    anchors.margins: units.gu(1.5)
                    spacing: units.gu(1.2)

                    RowLayout {
                        width: parent.width

                        Label {
                            text: i18n.tr("Live Heart Rate")
                            font.bold: true
                            font.pixelSize: units.gu(1.8)
                            color: root.textPrimaryColor
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            height: units.gu(2.6)
                            width: zoneLabel.width + units.gu(2)
                            radius: height / 2
                            color: root.backendBridge.heartRateZoneColor

                            Label {
                                id: zoneLabel
                                text: root.backendBridge.heartRateZone
                                font.bold: true
                                font.pixelSize: units.gu(1.2)
                                color: "white"
                                anchors.centerIn: parent
                            }
                        }
                    }

                    RowLayout {
                        width: parent.width
                        spacing: units.gu(2)

                        // Pulsing Heart Graphic
                        Rectangle {
                            width: units.gu(7)
                            height: units.gu(7)
                            radius: width / 2
                            color: root.isDarkMode ? "#3D2224" : "#FFEAEA"

                            Label {
                                id: heartIcon
                                text: "❤️"
                                font.pixelSize: units.gu(3.5)
                                anchors.centerIn: parent

                                SequentialAnimation on scale {
                                    running: root.backendBridge.connected && root.backendBridge.heartRate > 0
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 1.0; to: 1.25; duration: 250; easing.type: Easing.OutQuad }
                                    NumberAnimation { from: 1.25; to: 1.0; duration: 250; easing.type: Easing.InQuad }
                                    PauseAnimation { duration: Math.max(100, Math.round(60000 / Math.max(60, root.backendBridge.heartRate)) - 500) }
                                }
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: units.gu(0.2)

                            Row {
                                spacing: units.gu(0.8)

                                Label {
                                    text: root.backendBridge.connected ? root.backendBridge.heartRate.toString() : "--"
                                    font.bold: true
                                    font.pixelSize: units.gu(4)
                                    color: root.primaryColor
                                }

                                Label {
                                    text: "BPM"
                                    font.pixelSize: units.gu(1.6)
                                    font.bold: true
                                    color: root.textSecondaryColor
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: units.gu(0.6)
                                }
                            }

                            Label {
                                text: root.backendBridge.heartRateZoneDesc
                                font.pixelSize: units.gu(1.2)
                                color: root.textSecondaryColor
                            }
                        }
                    }

                    // Zone scale indicator
                    Row {
                        width: parent.width
                        height: units.dp(6)
                        spacing: units.dp(3)

                        Rectangle { width: (parent.width - 12) / 5; height: parent.height; radius: 3; color: "#38BDF8"; opacity: root.backendBridge.heartRateZone === "Rest" ? 1.0 : 0.3 }
                        Rectangle { width: (parent.width - 12) / 5; height: parent.height; radius: 3; color: "#34D399"; opacity: root.backendBridge.heartRateZone === "Warm-up" ? 1.0 : 0.3 }
                        Rectangle { width: (parent.width - 12) / 5; height: parent.height; radius: 3; color: "#FBBF24"; opacity: root.backendBridge.heartRateZone === "Fat Burn" ? 1.0 : 0.3 }
                        Rectangle { width: (parent.width - 12) / 5; height: parent.height; radius: 3; color: "#FB923C"; opacity: root.backendBridge.heartRateZone === "Cardio" ? 1.0 : 0.3 }
                        Rectangle { width: (parent.width - 12) / 5; height: parent.height; radius: 3; color: "#EF4444"; opacity: root.backendBridge.heartRateZone === "Peak" ? 1.0 : 0.3 }
                    }
                }
            }

            // STEP COUNT & PEDOMETER TELEMETRY CARD
            Rectangle {
                width: parent.width
                height: units.gu(16)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)

                Column {
                    anchors.fill: parent
                    anchors.margins: units.gu(1.5)
                    spacing: units.gu(1.2)

                    RowLayout {
                        width: parent.width

                        Label {
                            text: i18n.tr("Today's Steps (Xiaomi Band 9)")
                            font.bold: true
                            font.pixelSize: units.gu(1.8)
                            color: root.textPrimaryColor
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            text: root.backendBridge.stepProgressPct + "%"
                            font.bold: true
                            font.pixelSize: units.gu(1.5)
                            color: root.accentGreen
                        }
                    }

                    RowLayout {
                        width: parent.width

                        Column {
                            Layout.fillWidth: true
                            spacing: units.gu(0.2)

                            Label {
                                text: root.backendBridge.steps.toLocaleString()
                                font.bold: true
                                font.pixelSize: units.gu(3.2)
                                color: root.textPrimaryColor
                            }

                            Label {
                                text: i18n.tr("Goal: ") + root.backendBridge.stepGoal.toLocaleString() + i18n.tr(" steps")
                                font.pixelSize: units.gu(1.2)
                                color: root.textSecondaryColor
                            }
                        }

                        Column {
                            spacing: units.gu(0.5)

                            Label {
                                text: "📍 " + root.backendBridge.distanceKm + " km"
                                font.pixelSize: units.gu(1.4)
                                font.bold: true
                                color: root.accentBlue
                            }

                            Label {
                                text: "🔥 " + root.backendBridge.caloriesBurned + " kcal"
                                font.pixelSize: units.gu(1.4)
                                font.bold: true
                                color: root.accentOrange
                            }
                        }
                    }

                    // Step progress bar
                    Rectangle {
                        width: parent.width
                        height: units.gu(1)
                        radius: height / 2
                        color: root.isDarkMode ? "#373A40" : "#E9ECEF"

                        Rectangle {
                            width: Math.min(parent.width, Math.max(units.gu(1), parent.width * (root.backendBridge.stepProgressPct / 100)))
                            height: parent.height
                            radius: parent.radius
                            color: root.accentGreen

                            Behavior on width {
                                NumberAnimation { duration: 400; easing.type: Easing.OutQuad }
                            }
                        }
                    }
                }
            }

            // BACKEND BRIDGE PROTOCOL INFO CARD
            Rectangle {
                width: parent.width
                height: units.gu(12)
                radius: units.dp(12)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)

                Column {
                    anchors.fill: parent
                    anchors.margins: units.gu(1.5)
                    spacing: units.gu(0.8)

                    Label {
                        text: i18n.tr("Python Backend Bridge Architecture")
                        font.bold: true
                        font.pixelSize: units.gu(1.5)
                        color: root.textPrimaryColor
                    }

                    Label {
                        text: i18n.tr("• Interfaces with BlueZ GATT using Gadgetbridge open protocol specs")
                        font.pixelSize: units.gu(1.2)
                        color: root.textSecondaryColor
                    }

                    Label {
                        text: i18n.tr("• Realtime Heart Rate Service (0x180D) & Step Activity (0xFEE0)")
                        font.pixelSize: units.gu(1.2)
                        color: root.textSecondaryColor
                    }

                    Label {
                        text: i18n.tr("• High-frequency workout mode with dynamic caloric calculations")
                        font.pixelSize: units.gu(1.2)
                        color: root.textSecondaryColor
                    }
                }
            }
        }
    }
}
