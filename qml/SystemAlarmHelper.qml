import QtQuick 2.7
import Ubuntu.Components 1.3

Item {
    id: systemAlarmHelper

    property bool isSupported: false

    Alarm {
        id: alarmItem
        type: Alarm.OneTime
        enabled: true
    }

    Component.onCompleted: {
        try {
            isSupported = (typeof alarmItem !== "undefined" && typeof alarmItem.save === "function")
            console.log("SystemAlarmHelper: isSupported =", isSupported)
        } catch (e) {
            console.log("SystemAlarmHelper: initialization error:", e)
            isSupported = false
        }
    }

    function scheduleAlarm(seconds, title, message) {
        if (!isSupported) {
            console.log("SystemAlarmHelper: Alarm not supported on this device/runtime.")
            return false
        }

        try {
            // Cancel any previously scheduled alarm
            try {
                alarmItem.cancel()
            } catch (ce) {}

            alarmItem.reset()
            alarmItem.type = Alarm.OneTime
            alarmItem.enabled = true
            // Ubuntu.Components.Alarm requires date as a Date object in the future
            alarmItem.date = new Date(Date.now() + (seconds * 1000))
            alarmItem.message = (title ? title + ": " : "") + (message ? message : "")
            alarmItem.save()

            if (alarmItem.error === Alarm.NoError) {
                console.log("SystemAlarmHelper: OS Alarm successfully registered for:", alarmItem.date.toISOString())
                return true
            } else {
                console.log("SystemAlarmHelper: Alarm.save() returned error code:", alarmItem.error)
                return false
            }
        } catch (e) {
            console.log("SystemAlarmHelper: Exception during scheduleAlarm:", e)
            return false
        }
    }

    function cancelAlarm() {
        if (!isSupported) return
        try {
            alarmItem.cancel()
            console.log("SystemAlarmHelper: OS Alarm successfully cancelled.")
        } catch (e) {
            console.log("SystemAlarmHelper: Exception during cancelAlarm:", e)
        }
    }
}
