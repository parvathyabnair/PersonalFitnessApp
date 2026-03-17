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
    
    
    Component.onCompleted: {
    DB.createTable()
}




    PageStack {
        id: pageStack
        anchors.fill: parent

        Component.onCompleted: push(homePage)
    }

    Component {
        id: homePage
        HomePage { }
    }

    SplashScreen {
        id: splashScreen
        anchors.fill: parent
        appName: "Personal Fitness App"
        appVersion: "1.0.0"
        minimumTime: 5000 // 5 seconds
        ready: true // Set to true to allow splash to finish after minimumTime
        visible: showSplash
        z: 1000

        onFinished: {
            showSplash = false
        }
    }

   
}
