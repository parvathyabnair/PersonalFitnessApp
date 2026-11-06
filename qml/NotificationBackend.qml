import QtQuick 2.7
import io.thp.pyotherside 1.4

Item {
    id: backendRoot

    property bool isReady: false
    property var pendingSchedule: null
    property string pendingToken: ""

    Python {
        id: py

        Component.onCompleted: {
            var rootUrl = Qt.resolvedUrl("..").toString().replace("file://", "")
            var localUrl = Qt.resolvedUrl(".").toString().replace("file://", "")
            addImportPath(rootUrl)
            addImportPath(localUrl)

            importModule("backend", function() {
                console.log("PyOtherSide: backend.py loaded successfully")
                backendRoot.isReady = true
                py.call("backend.ensure_daemon", [], function(res) {
                    console.log("Background daemon ensured on startup:", res)
                })

                if (backendRoot.pendingToken && backendRoot.pendingToken.length > 0) {
                    py.call("backend.save_token", [backendRoot.pendingToken], function(res) {
                        console.log("Queued push token saved:", res)
                    })
                    backendRoot.pendingToken = ""
                }
                if (backendRoot.pendingSchedule) {
                    var fn = backendRoot.pendingSchedule
                    backendRoot.pendingSchedule = null
                    fn()
                }
            })
        }

        onError: {
            console.log("PyOtherSide error:", traceback)
        }
    }

    function ensureDaemon() {
        if (!isReady) return
        py.call("backend.ensure_daemon", [], function(res) {
            console.log("Daemon ensure result:", res)
        })
    }

    function savePushToken(token) {
        if (!token) return
        if (!isReady) {
            pendingToken = token
            return
        }
        py.call("backend.save_token", [token], function(res) {
            console.log("Push token saved in background:", res)
        })
    }

    function schedule(seconds, title, message) {
        if (!isReady) {
            console.log("NotificationBackend: Queuing schedule until backend is ready...")
            pendingSchedule = function() {
                py.call("backend.schedule_notification", [seconds, title, message], function(res) {
                    console.log("Queued notification scheduled in background:", res)
                })
            }
            return
        }
        py.call("backend.schedule_notification", [seconds, title, message], function(res) {
            console.log("Notification scheduled in background:", res)
        })
    }

    function cancel() {
        pendingSchedule = null
        if (!isReady) return
        py.call("backend.cancel_notification", [], function(res) {
            console.log("Scheduled notification cancelled:", res)
        })
    }

    function dispatchNow(title, message) {
        if (!isReady) return
        py.call("backend.dispatch_now", [title, message], function(res) {
            console.log("Notification dispatched immediately:", res)
        })
    }
}
