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
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import "database.js" as DB

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'personalfitnessapp.parvathy'
    automaticOrientation: true

    width: units.gu(45)
    height: units.gu(75)
    backgroundColor: isDarkMode ? "#121214" : "#F8F9FA"
    property bool showSplash: true

    // Real-time synchronization signal across convergent split columns
    signal sessionDataChanged()

    // THEME PALETTE HELPERS (Used consistently across all pages)
    readonly property bool isDarkMode: Theme.name === "Ubuntu.Components.Themes.SuruDark"
    readonly property color primaryColor: '#fc5d5d'
    readonly property color secondaryColor: '#79cff2'
    readonly property color primaryHoverColor: "#fd7e7e"
    readonly property color primaryLightColor: isDarkMode ? "#3D2020" : "#FDEAEA"
    readonly property color secondaryLightColor: isDarkMode ? "#162832" : "#EAF7FD"
    readonly property color cardBgColor: isDarkMode ? "#25262B" : "#FFFFFF"
    readonly property color cardBorderColor: isDarkMode ? "#373A40" : "#E9ECEF"
    readonly property color textPrimaryColor: isDarkMode ? "#F8F9FA" : "#1A1B1E"
    readonly property color textSecondaryColor: isDarkMode ? "#A0A0A5" : "#6C757D"
    readonly property color accentBlue: secondaryColor
    readonly property color accentGreen: isDarkMode ? "#34D399" : "#10B981"
    readonly property color accentOrange: isDarkMode ? "#FB923C" : "#F97316"

    // GLOBAL SESSION STATE (Accurate Wall-Clock Timekeeper using Date.now())
    property int activeSessionId: -1
    property string activeSessionWorkout: ""
    property int activeSessionSeconds: 0
    property bool activeSessionRunning: false
    property int activeSessionTargetSeconds: -1

    property double sessionAccumulatedMs: 0
    property double lastResumeTimestamp: 0

    Settings {
        id: sessionStorage
        category: "ActiveWorkoutSession"
        property int savedSessionId: -1
        property string savedWorkout: ""
        property bool savedRunning: false
        property int savedSeconds: 0
        property int savedTargetSeconds: -1
        property double savedAccumulatedMs: 0
        property double savedLastResumeTimestamp: 0
    }

    function syncSessionStorage() {
        sessionStorage.savedSessionId = activeSessionId
        sessionStorage.savedWorkout = activeSessionWorkout
        sessionStorage.savedRunning = activeSessionRunning
        sessionStorage.savedSeconds = activeSessionSeconds
        sessionStorage.savedTargetSeconds = activeSessionTargetSeconds
        sessionStorage.savedAccumulatedMs = sessionAccumulatedMs
        sessionStorage.savedLastResumeTimestamp = lastResumeTimestamp
    }

    onActiveSessionRunningChanged: {
        if (activeSessionRunning) {
            lastResumeTimestamp = Date.now()
        } else {
            if (lastResumeTimestamp > 0) {
                sessionAccumulatedMs += (Date.now() - lastResumeTimestamp)
                lastResumeTimestamp = 0
                activeSessionSeconds = Math.floor(sessionAccumulatedMs / 1000)
            }
        }
        syncSessionStorage()
    }

    onActiveSessionIdChanged: {
        syncSessionStorage()
    }

    function setSessionSeconds(newSecs) {
        var s = Math.max(0, parseInt(newSecs) || 0)
        activeSessionSeconds = s
        sessionAccumulatedMs = s * 1000
        if (activeSessionRunning) {
            lastResumeTimestamp = Date.now()
        } else {
            lastResumeTimestamp = 0
        }
        syncSessionStorage()
    }

    onActiveSessionSecondsChanged: {
        if (activeSessionSeconds === 0 && !activeSessionRunning) {
            sessionAccumulatedMs = 0
            lastResumeTimestamp = 0
            syncSessionStorage()
        }
    }

    function restoreActiveSessionState() {
        if (sessionStorage.savedSessionId !== -1) {
            activeSessionId = sessionStorage.savedSessionId
            activeSessionWorkout = sessionStorage.savedWorkout
            activeSessionTargetSeconds = sessionStorage.savedTargetSeconds
            if (sessionStorage.savedRunning && sessionStorage.savedLastResumeTimestamp > 0) {
                var now = Date.now()
                var elapsedMs = sessionStorage.savedAccumulatedMs + (now - sessionStorage.savedLastResumeTimestamp)
                var currentSecs = Math.floor(elapsedMs / 1000)
                if (activeSessionTargetSeconds > 0 && currentSecs >= activeSessionTargetSeconds) {
                    activeSessionSeconds = activeSessionTargetSeconds
                    sessionAccumulatedMs = activeSessionTargetSeconds * 1000
                    activeSessionRunning = false
                    lastResumeTimestamp = 0
                } else {
                    activeSessionSeconds = currentSecs
                    sessionAccumulatedMs = elapsedMs
                    lastResumeTimestamp = now
                    activeSessionRunning = true
                }
            } else {
                activeSessionSeconds = sessionStorage.savedSeconds
                sessionAccumulatedMs = sessionStorage.savedAccumulatedMs
                activeSessionRunning = false
                lastResumeTimestamp = 0
            }
            syncSessionStorage()
        }
    }

    Timer {
        id: globalSessionTimer
        interval: 200 // Refresh 5x/sec, recalculating against real Date.now()
        running: activeSessionRunning
        repeat: true
        onTriggered: {
            if (activeSessionRunning && lastResumeTimestamp > 0) {
                var now = Date.now()
                var elapsedMs = sessionAccumulatedMs + (now - lastResumeTimestamp)
                var currentSecs = Math.floor(elapsedMs / 1000)
                if (currentSecs !== activeSessionSeconds) {
                    activeSessionSeconds = currentSecs
                    sessionStorage.savedSeconds = currentSecs
                }
                if (activeSessionTargetSeconds > 0 && currentSecs >= activeSessionTargetSeconds) {
                    activeSessionSeconds = activeSessionTargetSeconds
                    activeSessionRunning = false
                }
            }
        }
    }

    // GLOBAL TIMELY REMINDER & NOTIFICATION SYSTEM
    property bool reminderActive: false
    property bool reminderPaused: false
    property int reminderIntervalSeconds: 2700 // default 45 mins
    property int reminderSecondsLeft: 0
    property string reminderTitle: i18n.tr("Time to Hydrate!")
    property string reminderMessage: i18n.tr("Take a refreshing drink of water to keep your hydration on track.")
    property bool reminderRepeat: true
    property string reminderType: "water" // "water" or "custom"
    property double reminderTargetTimestamp: 0
    property bool showReminderNotification: false

    Settings {
        id: reminderStorage
        category: "TimelyReminder"
        property bool savedActive: false
        property bool savedPaused: false
        property int savedIntervalSeconds: 2700
        property int savedSecondsLeft: 2700
        property double savedTargetTimestamp: 0
        property string savedTitle: "Time to Hydrate!"
        property string savedMessage: "Take a refreshing drink of water to keep your hydration on track."
        property bool savedRepeat: true
        property string savedType: "water"
    }

    Timer {
        id: reminderTicker
        interval: 1000
        running: reminderActive && !reminderPaused
        repeat: true
        onTriggered: {
            if (reminderActive && !reminderPaused && reminderTargetTimestamp > 0) {
                var diffMs = reminderTargetTimestamp - Date.now()
                if (diffMs <= 0) {
                    reminderSecondsLeft = 0
                    triggerReminderNotification()
                } else {
                    reminderSecondsLeft = Math.ceil(diffMs / 1000)
                }
            }
        }
    }

    function triggerReminderNotification() {
        showReminderNotification = true
        if (reminderRepeat) {
            var target = Date.now() + (reminderIntervalSeconds * 1000)
            reminderTargetTimestamp = target
            reminderSecondsLeft = reminderIntervalSeconds
            reminderActive = true
            reminderPaused = false

            reminderStorage.savedActive = true
            reminderStorage.savedPaused = false
            reminderStorage.savedTargetTimestamp = target
            reminderStorage.savedSecondsLeft = reminderIntervalSeconds
        } else {
            reminderActive = false
            reminderPaused = false
            reminderSecondsLeft = 0
            reminderTargetTimestamp = 0

            reminderStorage.savedActive = false
            reminderStorage.savedPaused = false
            reminderStorage.savedTargetTimestamp = 0
            reminderStorage.savedSecondsLeft = 0
        }
    }

    function startReminder(seconds, title, message, repeat, type) {
        var s = parseInt(seconds) || 2700
        reminderIntervalSeconds = s
        reminderSecondsLeft = s
        reminderTitle = title || i18n.tr("Time to Hydrate!")
        reminderMessage = message || i18n.tr("Take a refreshing drink of water to keep your hydration on track.")
        reminderRepeat = (typeof repeat !== "undefined") ? repeat : true
        reminderType = type || "water"
        var target = Date.now() + (s * 1000)
        reminderTargetTimestamp = target
        reminderPaused = false
        reminderActive = true

        reminderStorage.savedActive = true
        reminderStorage.savedPaused = false
        reminderStorage.savedIntervalSeconds = s
        reminderStorage.savedSecondsLeft = s
        reminderStorage.savedTargetTimestamp = target
        reminderStorage.savedTitle = reminderTitle
        reminderStorage.savedMessage = reminderMessage
        reminderStorage.savedRepeat = reminderRepeat
        reminderStorage.savedType = reminderType
    }

    function pauseReminder() {
        if (reminderActive) {
            if (reminderTargetTimestamp > 0) {
                reminderSecondsLeft = Math.max(1, Math.ceil((reminderTargetTimestamp - Date.now()) / 1000))
            }
            reminderActive = false
            reminderPaused = true
            reminderTargetTimestamp = 0

            reminderStorage.savedActive = false
            reminderStorage.savedPaused = true
            reminderStorage.savedSecondsLeft = reminderSecondsLeft
            reminderStorage.savedTargetTimestamp = 0
        }
    }

    function resumeReminder() {
        if (reminderPaused) {
            if (reminderSecondsLeft <= 0) {
                reminderSecondsLeft = reminderIntervalSeconds > 0 ? reminderIntervalSeconds : 2700
            }
            var target = Date.now() + (reminderSecondsLeft * 1000)
            reminderTargetTimestamp = target
            reminderPaused = false
            reminderActive = true

            reminderStorage.savedActive = true
            reminderStorage.savedPaused = false
            reminderStorage.savedTargetTimestamp = target
            reminderStorage.savedSecondsLeft = reminderSecondsLeft
        }
    }

    function stopReminder() {
        reminderActive = false
        reminderPaused = false
        reminderSecondsLeft = 0
        reminderTargetTimestamp = 0
        showReminderNotification = false

        reminderStorage.savedActive = false
        reminderStorage.savedPaused = false
        reminderStorage.savedTargetTimestamp = 0
        reminderStorage.savedSecondsLeft = 0
    }

    function snoozeReminder(minutes) {
        var mins = parseInt(minutes) || 10
        var s = mins * 60
        reminderSecondsLeft = s
        reminderPaused = false
        var target = Date.now() + (s * 1000)
        reminderTargetTimestamp = target
        reminderActive = true
        showReminderNotification = false

        reminderStorage.savedActive = true
        reminderStorage.savedPaused = false
        reminderStorage.savedTargetTimestamp = target
        reminderStorage.savedSecondsLeft = s
    }

    function dismissReminderNotification() {
        showReminderNotification = false
    }

    function triggerManualNotification(title, message, isWater) {
        if (title) reminderTitle = title
        if (message) reminderMessage = message
        reminderType = isWater ? "water" : "custom"
        showReminderNotification = true
    }

    function restoreReminderState() {
        reminderIntervalSeconds = reminderStorage.savedIntervalSeconds > 0 ? reminderStorage.savedIntervalSeconds : 2700
        reminderTitle = reminderStorage.savedTitle || i18n.tr("Time to Hydrate!")
        reminderMessage = reminderStorage.savedMessage || i18n.tr("Take a refreshing drink of water to keep your hydration on track.")
        reminderRepeat = (typeof reminderStorage.savedRepeat !== "undefined") ? reminderStorage.savedRepeat : true
        reminderType = reminderStorage.savedType || "water"

        if (reminderStorage.savedPaused) {
            reminderActive = false
            reminderPaused = true
            reminderTargetTimestamp = 0
            reminderSecondsLeft = Math.max(1, reminderStorage.savedSecondsLeft > 0 ? reminderStorage.savedSecondsLeft : reminderIntervalSeconds)
        } else if (reminderStorage.savedActive && reminderStorage.savedTargetTimestamp > 0) {
            var now = Date.now()
            var diffMs = reminderStorage.savedTargetTimestamp - now
            if (diffMs > 0) {
                reminderActive = true
                reminderPaused = false
                reminderTargetTimestamp = reminderStorage.savedTargetTimestamp
                reminderSecondsLeft = Math.ceil(diffMs / 1000)
            } else {
                if (reminderRepeat) {
                    var elapsed = now - reminderStorage.savedTargetTimestamp
                    var intervalMs = reminderIntervalSeconds * 1000
                    var remainderMs = intervalMs - (elapsed % intervalMs)
                    reminderTargetTimestamp = now + remainderMs
                    reminderSecondsLeft = Math.ceil(remainderMs / 1000)
                    reminderActive = true
                    reminderPaused = false
                    reminderStorage.savedTargetTimestamp = reminderTargetTimestamp
                    reminderStorage.savedSecondsLeft = reminderSecondsLeft
                    showReminderNotification = true
                } else {
                    reminderActive = false
                    reminderPaused = false
                    reminderSecondsLeft = 0
                    reminderTargetTimestamp = 0
                    reminderStorage.savedActive = false
                    reminderStorage.savedTargetTimestamp = 0
                    reminderStorage.savedSecondsLeft = 0
                    showReminderNotification = true
                }
            }
        } else {
            reminderActive = false
            reminderPaused = false
            reminderSecondsLeft = 0
            reminderTargetTimestamp = 0
        }
    }

    Connections {
        target: Qt.application
        onStateChanged: {
            if (Qt.application.state === Qt.ApplicationActive) {
                if (reminderActive && !reminderPaused && reminderTargetTimestamp > 0) {
                    var diffMs = reminderTargetTimestamp - Date.now()
                    if (diffMs <= 0) {
                        reminderSecondsLeft = 0
                        triggerReminderNotification()
                    } else {
                        reminderSecondsLeft = Math.ceil(diffMs / 1000)
                    }
                }
                if (activeSessionRunning && lastResumeTimestamp > 0) {
                    var now = Date.now()
                    var elapsedMs = sessionAccumulatedMs + (now - lastResumeTimestamp)
                    activeSessionSeconds = Math.floor(elapsedMs / 1000)
                }
            }
        }
    }

    Component.onCompleted: {
        DB.createTable()
        restoreReminderState()
        restoreActiveSessionState()
    }

    AdaptivePageLayout {
        id: pageLayout
        anchors.fill: parent

        layouts: [
            PageColumnsLayout {
                when: width >= units.gu(80) && width < units.gu(130)

                PageColumn {
                    minimumWidth: units.gu(35)
                    maximumWidth: units.gu(55)
                    preferredWidth: units.gu(40)
                }

                PageColumn {
                    fillWidth: true
                }
            },

            PageColumnsLayout {
                when: width >= units.gu(130)

                PageColumn {
                    minimumWidth: units.gu(35)
                    maximumWidth: units.gu(48)
                    preferredWidth: units.gu(40)
                }

                PageColumn {
                    minimumWidth: units.gu(40)
                    maximumWidth: units.gu(55)
                    preferredWidth: units.gu(45)
                }

                PageColumn {
                    fillWidth: true
                }
            }
        ]

        primaryPage: HomePage {
            id: homePage
            pageLayout: pageLayout
        }
    }

    // FLOATING TIMELY REMINDER NOTIFICATION BANNER
    Rectangle {
        id: notificationBanner
        z: 990
        width: Math.min(parent.width - units.gu(4), units.gu(46))
        height: bannerCol.height + units.gu(2.8)
        radius: units.dp(16)
        color: root.isDarkMode ? "#25262B" : "#FFFFFF"
        border.color: reminderType === "water" ? root.secondaryColor : root.primaryColor
        border.width: units.dp(2)
        anchors.horizontalCenter: parent.horizontalCenter

        // Slide down from top with spring animation
        y: showReminderNotification ? units.gu(3) : -height - units.gu(8)
        opacity: showReminderNotification ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on y {
            NumberAnimation { duration: 380; easing.type: Easing.OutBack }
        }
        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: reminderType === "water" ? Qt.rgba(root.secondaryColor.r, root.secondaryColor.g, root.secondaryColor.b, 0.15) : Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, 0.15)
            z: -1
        }

        Column {
            id: bannerCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: units.gu(1.4)
            spacing: units.gu(1.2)

            // Header: Icon + Title + Close Button
            RowLayout {
                width: parent.width

                Rectangle {
                    width: units.gu(3.8)
                    height: units.gu(3.8)
                    radius: width / 2
                    color: reminderType === "water" ? Qt.rgba(56/255, 189/255, 248/255, 0.2) : Qt.rgba(255/255, 82/255, 82/255, 0.2)

                    Label {
                        anchors.centerIn: parent
                        text: reminderType === "water" ? "💧" : "⏰"
                        font.pixelSize: units.gu(1.8)
                    }
                }

                Column {
                    Layout.fillWidth: true
                    spacing: units.gu(0.2)

                    Label {
                        text: root.reminderTitle
                        font.bold: true
                        font.pixelSize: units.gu(1.4)
                        color: root.textPrimaryColor
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Label {
                        text: i18n.tr("Timely Reminder • Just now")
                        font.pixelSize: units.gu(0.95)
                        color: root.textSecondaryColor
                    }
                }

                // Close Button
                Rectangle {
                    width: units.gu(3.2)
                    height: units.gu(3.2)
                    radius: width / 2
                    color: closeMouse.pressed ? root.cardBorderColor : "transparent"

                    Label {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: units.gu(1.3)
                        color: root.textSecondaryColor
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dismissReminderNotification()
                    }
                }
            }

            // Message Body
            Label {
                width: parent.width
                text: root.reminderMessage
                wrapMode: Text.WordWrap
                font.pixelSize: units.gu(1.15)
                color: root.textPrimaryColor
                lineHeight: 1.15
            }

            // Action Buttons
            Row {
                width: parent.width
                spacing: units.gu(1)

                // If water reminder: Cup and Bottle log buttons
                Button {
                    visible: root.reminderType === "water"
                    text: i18n.tr("+250 ml (Cup)")
                    color: root.secondaryColor
                    width: (parent.width - units.gu(2)) / 3
                    height: units.gu(3.8)
                    onClicked: {
                        DB.addWater(250)
                        root.sessionDataChanged()
                        root.dismissReminderNotification()
                    }
                }

                Button {
                    visible: root.reminderType === "water"
                    text: i18n.tr("+500 ml")
                    color: root.secondaryColor
                    width: (parent.width - units.gu(2)) / 3
                    height: units.gu(3.8)
                    onClicked: {
                        DB.addWater(500)
                        root.sessionDataChanged()
                        root.dismissReminderNotification()
                    }
                }

                // If custom non-water reminder: Done button
                Button {
                    visible: root.reminderType !== "water"
                    text: i18n.tr("Done 💪")
                    color: root.accentGreen
                    width: (parent.width - units.gu(1)) / 2
                    height: units.gu(3.8)
                    onClicked: {
                        root.dismissReminderNotification()
                    }
                }

                // Snooze 10m
                Button {
                    text: i18n.tr("Snooze (10m)")
                    color: root.cardBorderColor
                    width: root.reminderType === "water" ? ((parent.width - units.gu(2)) / 3) : ((parent.width - units.gu(1)) / 2)
                    height: units.gu(3.8)
                    onClicked: {
                        root.snoozeReminder(10)
                    }
                }
            }
        }
    }

    SplashScreen {
        id: splashScreen
        anchors.fill: parent
        appName: "Personal Fitness App"
        appVersion: "1.0.0"
        minimumTime: 1800 // Snappy and responsive splash
        ready: true
        visible: showSplash
        z: 1000

        onFinished: {
            showSplash = false
        }
    }
}
