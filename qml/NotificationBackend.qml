import QtQuick 2.7
import io.thp.pyotherside 1.4

Item {
    id: backendRoot

    property bool isReady: false

    Python {
        id: py

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl(".."))
            addImportPath(Qt.resolvedUrl("."))

            importModule("backend", function() {
                console.log("PyOtherSide: backend.py loaded successfully")
                backendRoot.isReady = true
            })
        }

        onError: {
            console.log("PyOtherSide error:", traceback)
        }
    }

    function schedule(seconds, title, message) {
        if (!isReady) return
        py.call("backend.schedule_notification", [seconds, title, message], function(res) {
            console.log("Notification scheduled in background:", res)
        })
    }

    function cancel() {
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

