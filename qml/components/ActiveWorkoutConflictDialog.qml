/*
 * Copyright (C) 2026  Parvathy Nair
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * personalfitnessapp is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
import QtQuick.Layouts 1.3

Dialog {
    id: conflictDialog
    title: i18n.tr("Workout in Progress")

    property var onProceedCallback: null
    property bool wasRunning: (typeof root !== "undefined") ? root.activeSessionRunning : false

    property string workoutName: {
        if (typeof root !== "undefined" && root.activeSessionWorkout && root.activeSessionWorkout !== "") {
            return root.activeSessionWorkout;
        }
        return i18n.tr("Active Workout");
    }

    property int elapsedSeconds: (typeof root !== "undefined") ? root.activeSessionSeconds : 0

    property string elapsedTimeText: {
        var sec = elapsedSeconds;
        var h = Math.floor(sec / 3600);
        var m = Math.floor((sec % 3600) / 60);
        var s = sec % 60;
        return ("0" + h).slice(-2) + ":" + ("0" + m).slice(-2) + ":" + ("0" + s).slice(-2);
    }

    signal saveAndProceedTriggered()
    signal discardAndProceedTriggered()
    signal cancelTriggered()

    Component.onCompleted: {
        if (typeof root !== "undefined" && root.activeSessionRunning) {
            wasRunning = true;
            root.activeSessionRunning = false;
        }
    }

    Column {
        width: parent.width
        spacing: units.gu(1.6)

        // Running workout info card
        Rectangle {
            width: parent.width
            height: units.gu(7.2)
            radius: units.dp(10)
            color: (typeof root !== "undefined" && root.isDarkMode) ? "#2A2D35" : "#F3F4F6"
            border.color: (typeof root !== "undefined") ? root.cardBorderColor : "#E5E7EB"
            border.width: units.dp(1)

            RowLayout {
                anchors.fill: parent
                anchors.margins: units.gu(1.2)
                spacing: units.gu(1.2)

                Rectangle {
                    width: units.gu(4.4)
                    height: units.gu(4.4)
                    radius: width / 2
                    color: Qt.rgba(239/255, 68/255, 68/255, 0.15)
                    Layout.alignment: Qt.AlignVCenter

                    Icon {
                        name: "alarm-clock"
                        width: units.gu(2.2)
                        height: units.gu(2.2)
                        color: "#EF4444"
                        anchors.centerIn: parent
                    }
                }

                Column {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: units.dp(2)

                    Label {
                        text: workoutName
                        font.bold: true
                        font.pixelSize: units.gu(1.4)
                        color: (typeof root !== "undefined") ? root.textPrimaryColor : "#111827"
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Label {
                        text: i18n.tr("Elapsed: ") + elapsedTimeText
                        font.pixelSize: units.gu(1.2)
                        color: (typeof root !== "undefined") ? root.textSecondaryColor : "#6B7280"
                    }
                }
            }
        }

        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            text: i18n.tr("A session is currently in progress. You must either save or discard it before creating a new workout.")
            font.pixelSize: units.gu(1.2)
            color: (typeof root !== "undefined") ? root.textSecondaryColor : "#4B5563"
        }

        // Action Buttons
        Column {
            width: parent.width
            spacing: units.gu(1.0)

            Button {
                id: saveBtn
                objectName: "saveProceedButton"
                width: parent.width
                height: units.gu(4.6)
                color: (typeof root !== "undefined") ? root.primaryColor : "#FF5252"
                text: i18n.tr("Save Current & Proceed")
                onClicked: {
                    conflictDialog.saveAndProceedTriggered();
                    PopupUtils.close(conflictDialog);
                    if (typeof root !== "undefined" && typeof root.saveCurrentSessionAndReset === "function") {
                        root.saveCurrentSessionAndReset(onProceedCallback);
                    } else if (typeof onProceedCallback === "function") {
                        onProceedCallback();
                    }
                }
            }

            Button {
                id: discardBtn
                objectName: "discardProceedButton"
                width: parent.width
                height: units.gu(4.6)
                color: "#EF4444"
                text: i18n.tr("Discard Current & Proceed")
                onClicked: {
                    conflictDialog.discardAndProceedTriggered();
                    PopupUtils.close(conflictDialog);
                    if (typeof root !== "undefined" && typeof root.discardCurrentSessionAndReset === "function") {
                        root.discardCurrentSessionAndReset(onProceedCallback);
                    } else if (typeof onProceedCallback === "function") {
                        onProceedCallback();
                    }
                }
            }

            Button {
                id: cancelBtn
                objectName: "cancelKeepButton"
                width: parent.width
                height: units.gu(4.6)
                color: (typeof root !== "undefined") ? root.cardBorderColor : "#E5E7EB"
                text: i18n.tr("Cancel (Keep Current)")
                onClicked: {
                    conflictDialog.cancelTriggered();
                    if (wasRunning && typeof root !== "undefined") {
                        root.activeSessionRunning = true;
                    }
                    PopupUtils.close(conflictDialog);
                }
            }
        }
    }
}

