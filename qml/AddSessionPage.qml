import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import QtQml.Models 2.3
import QtGraphicalEffects 1.0
import "database.js" as DB
import "components"

Page {
    id: addSessionPage
    anchors.fill: parent
    property var pageLayout
    property bool showSearch: false

    header: PageHeader {
        title: i18n.tr("Session Overview")
        trailingActionBar.numberOfSlots: 2

        StyleHints {
            foregroundColor: "white"
            backgroundColor: root.primaryColor
            dividerColor: LomiriColors.slate
        }

        trailingActionBar.actions: [
            Action {
                iconName: "find"
                text: i18n.tr("Search")
                onTriggered: {
                    showSearch = !showSearch
                    if (!showSearch) {
                        refreshModel("")
                    }
                }
            },
            Action {
                iconName: "add"
                text: i18n.tr("New Workout")
                onTriggered: {
                    pageLayout.addPageToNextColumn(
                        pageLayout.primaryPage,
                        Qt.resolvedUrl("SessionCreatePage.qml"),
                        { pageLayout: pageLayout }
                    )
                }
            }
        ]
    }

    function refreshModel(query) {
        sessionModel.clear()
        var sessions = DB.getSessions(query)
        
        var today = new Date()
        var todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate())
        var todayEnd = new Date(todayStart.getTime() + 24 * 60 * 60 * 1000)
        
        var weekStart = new Date(todayStart.getTime() - today.getDay() * 24 * 60 * 60 * 1000)
        var monthStart = new Date(today.getFullYear(), today.getMonth(), 1)
        
        for (var i = 0; i < sessions.length; i++) {
            var s = sessions[i]
            var sessionDate = new Date(s.date)
            var sessionDateStart = new Date(sessionDate.getFullYear(), sessionDate.getMonth(), sessionDate.getDate())
            
            var include = true
            if (topFilterBar.currentFilter === "today") { 
                if (sessionDateStart < todayStart || sessionDateStart >= todayEnd) include = false
            } else if (topFilterBar.currentFilter === "this_week") { 
                if (sessionDateStart < weekStart || sessionDateStart >= todayEnd) include = false 
            } else if (topFilterBar.currentFilter === "this_month") { 
                if (sessionDateStart < monthStart || sessionDateStart >= todayEnd) include = false
            }
            
            if (include) {
                sessionModel.append({
                    id: s.id,
                    workout: s.workout,
                    sets: s.sets,
                    reps: s.reps,
                    weight: s.weight,
                    date: s.date,
                    duration: s.duration,
                    calories: s.calories
                })
            }
        }
    }

    Component.onCompleted: {
        refreshModel("")
    }

    ListModel {
        id: sessionModel
    }

    Item {
        anchors.fill: parent
        anchors.topMargin: header.height + units.gu(1)

        Column {
            id: topSection
            width: parent.width - units.gu(3)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: units.gu(1.2)

            // MODERN FILTER PILLS
            Rectangle {
                id: topFilterBar
                width: parent.width
                height: units.gu(4.5)
                radius: units.dp(10)
                color: root.cardBgColor
                border.color: root.cardBorderColor
                border.width: units.dp(1)

                property string currentFilter: "today"

                Row {
                    anchors.fill: parent
                    anchors.margins: units.dp(3)
                    spacing: units.dp(4)

                    Repeater {
                        model: [
                            { key: "today", label: i18n.tr("Today") },
                            { key: "this_week", label: i18n.tr("This Week") },
                            { key: "this_month", label: i18n.tr("This Month") },
                            { key: "all", label: i18n.tr("All") }
                        ]

                        Rectangle {
                            width: (topFilterBar.width - units.dp(6) - units.dp(12)) / 4
                            height: parent.height
                            radius: units.dp(8)
                            property bool isSelected: topFilterBar.currentFilter === modelData.key
                            color: isSelected ? root.primaryColor : "transparent"

                            Label {
                                anchors.centerIn: parent
                                text: modelData.label
                                font.bold: parent.isSelected
                                font.pixelSize: units.gu(1.3)
                                color: parent.isSelected ? "white" : root.textSecondaryColor
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    topFilterBar.currentFilter = modelData.key
                                    refreshModel(searchField.visible ? searchField.text : "")
                                }
                            }
                        }
                    }
                }
            }

            // SEARCH BAR
            TextField {
                id: searchField
                visible: showSearch
                placeholderText: i18n.tr("Search workouts...")
                width: parent.width
                onTextChanged: refreshModel(text)
            }
        }

        // WORKOUT LIST VIEW
        ListView {
            id: listView
            width: parent.width
            anchors.top: topSection.bottom
            anchors.topMargin: units.gu(1.5)
            anchors.bottom: parent.bottom
            model: sessionModel
            clip: true
            visible: count > 0

            delegate: ListItem {
                width: parent.width
                height: units.gu(12)

                leadingActions: ListItemActions {
                    actions: [
                        Action {
                            iconName: "delete"
                            onTriggered: {
                                DB.deleteSession(model.id)
                                sessionModel.remove(index)
                            }
                        }
                    ]
                }

                trailingActions: ListItemActions {
                    actions: [
                        Action {
                            iconName: "edit"
                            onTriggered: openEditPage(model)
                        }
                    ]
                }

                // WORKOUT CARD CONTAINER
                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: units.gu(1.5)
                    anchors.rightMargin: units.gu(1.5)
                    anchors.topMargin: units.gu(0.4)
                    anchors.bottomMargin: units.gu(0.4)
                    radius: units.dp(10)
                    color: root.cardBgColor
                    border.color: root.cardBorderColor
                    border.width: units.dp(1)

                    MouseArea {
                        anchors.fill: parent
                        onClicked: openEditPage(model)

                        Column {
                            anchors.fill: parent
                            anchors.margins: units.gu(1.2)
                            spacing: units.gu(0.6)

                            // Top row: Workout title + Date
                            RowLayout {
                                width: parent.width

                                Label {
                                    Layout.fillWidth: true
                                    text: model.workout
                                    font.bold: true
                                    font.pixelSize: units.gu(1.8)
                                    color: root.textPrimaryColor
                                    elide: Text.ElideRight
                                }

                                Label {
                                    text: Qt.formatDate(new Date(model.date), "MMM d, yyyy")
                                    color: root.textSecondaryColor
                                    font.pixelSize: units.gu(1.2)
                                }
                            }

                            // Middle row: Sets, Reps and Weight details
                            Label {
                                text: {
                                    var weights = [];
                                    try { weights = JSON.parse(model.weight); } catch(e) {}
                                    var reps = [];
                                    if (model.reps) {
                                        try { reps = JSON.parse(model.reps); } catch(e) {}
                                    }
                                    var details = [];
                                    var maxLen = Math.max(weights ? weights.length : 0, reps ? reps.length : 0);
                                    for (var i = 0; i < maxLen; i++) {
                                        var w = (weights && weights[i] !== undefined && weights[i] !== "") ? weights[i] + "kg" : "";
                                        var r = (reps && reps[i] !== undefined && reps[i] !== "") ? reps[i] + " reps" : "";
                                        if (w !== "" && r !== "") {
                                            details.push(r + " @ " + w);
                                        } else if (w !== "") {
                                            details.push(w);
                                        } else if (r !== "") {
                                            details.push(r);
                                        }
                                    }
                                    var res = i18n.tr("Sets: ") + model.sets;
                                    if (details.length > 0) {
                                        res += " • " + details.join(", ");
                                    }
                                    return res;
                                }
                                color: root.textSecondaryColor
                                font.pixelSize: units.gu(1.3)
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            // Bottom row: Duration badge + Burned Calories in vibrant accent
                            RowLayout {
                                width: parent.width

                                Label {
                                    text: "⏱ " + formatTime(model.duration)
                                    color: root.textSecondaryColor
                                    font.pixelSize: units.gu(1.3)
                                }

                                Item { Layout.fillWidth: true }

                                Label {
                                    text: "🔥 " + (model.calories ? model.calories.toFixed(1) + " kcal" : "0.0 kcal")
                                    color: root.primaryColor
                                    font.bold: true
                                    font.pixelSize: units.gu(1.5)
                                }
                            }
                        }
                    }
                }
            }
        }

        // EMPTY STATE
        EmptyState {
            visible: sessionModel.count === 0
            anchors.centerIn: parent
            title: i18n.tr("No Workouts Found")
            message: i18n.tr("No sessions match the selected filter. Tap + to log your workout!")
        }
    }

    function openEditPage(m) {
        pageLayout.addPageToNextColumn(
            pageLayout.primaryPage,
            Qt.resolvedUrl("SessionCreatePage.qml"),
            {
                pageLayout: pageLayout,   
                isEditMode: true,
                sessionId: m.id,
                workout: m.workout,
                sets: m.sets,
                reps: m.reps,
                weight: m.weight,
                date: m.date,
                duration: m.duration
            }
        )
    }

    function formatTime(sec) {
        if (!sec) return "00:00:00"
        var hours = Math.floor(sec / 3600)
        var mins = Math.floor((sec % 3600) / 60)
        var secs = sec % 60
        return ("0" + hours).slice(-2) + ":" + ("0" + mins).slice(-2) + ":" + ("0" + secs).slice(-2)
    }
}