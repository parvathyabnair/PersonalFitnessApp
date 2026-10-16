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
//import QtQuick.Controls 2.2
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
    property bool showSplash: true
    
    // THEME PALETTE HELPERS (Used consistently across all pages)
    readonly property bool isDarkMode: Theme.name === "Ubuntu.Components.Themes.SuruDark"
    readonly property color primaryColor: "#FF5252"
    readonly property color primaryHoverColor: "#FF6E6E"
    readonly property color primaryLightColor: isDarkMode ? "#3D2224" : "#FFEAEA"
    readonly property color cardBgColor: isDarkMode ? "#25262B" : "#FFFFFF"
    readonly property color cardBorderColor: isDarkMode ? "#373A40" : "#E9ECEF"
    readonly property color textPrimaryColor: isDarkMode ? "#F8F9FA" : "#1A1B1E"
    readonly property color textSecondaryColor: isDarkMode ? "#A0A0A5" : "#6C757D"
    readonly property color accentBlue: isDarkMode ? "#38BDF8" : "#0284C7"
    readonly property color accentGreen: isDarkMode ? "#34D399" : "#10B981"
    readonly property color accentOrange: isDarkMode ? "#FB923C" : "#F97316"
    
    // GLOBAL SESSION STATE
    property int activeSessionId: -1
    property string activeSessionWorkout: ""
    property int activeSessionSeconds: 0
    property bool activeSessionRunning: false
    property int activeSessionTargetSeconds: -1

    // WEARABLE BLUETOOTH BACKEND BRIDGE (Xiaomi Band 9 / Gadgetbridge)
    readonly property alias backendBridge: backendBridgeInstance
    BackendBridge {
        id: backendBridgeInstance
    }

    onActiveSessionRunningChanged: {
        backendBridgeInstance.setWorkoutMode(activeSessionRunning)
    }

    Timer {
        id: globalSessionTimer
        interval: 1000
        running: activeSessionRunning
        repeat: true
        onTriggered: {
            activeSessionSeconds++
            if (activeSessionTargetSeconds > 0 && activeSessionSeconds === activeSessionTargetSeconds) {
                activeSessionRunning = false
            }
        }
    }
    Component.onCompleted: {
        DB.createTable()
    }

    AdaptivePageLayout {
        id: pageLayout
        anchors.fill: parent

        primaryPage: HomePage {
            pageLayout: pageLayout
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
