import QtQuick 2.7
import Ubuntu.PushNotifications 0.1

Item {
    id: pushClientRoot
    signal notificationReceived(var notification)

    property string currentToken: ""

    function checkAndStoreToken() {
        if (pushClient.token && pushClient.token.length > 0) {
            pushClientRoot.currentToken = pushClient.token
            console.log("Push notification registration token:", pushClient.token)
            if (typeof notificationBackendLoader !== "undefined" &&
                notificationBackendLoader.item &&
                typeof notificationBackendLoader.item.savePushToken === "function") {
                notificationBackendLoader.item.savePushToken(pushClient.token)
            }
        }
    }

    PushClient {
        id: pushClient
        appId: "personalfitnessapp.parvathy_personalfitnessapp"

        onTokenChanged: {
            checkAndStoreToken()
        }

        onNotificationsChanged: {
            console.log("Push notifications changed, fetching...")
            try {
                pushClient.getNotifications()
            } catch(e) {
                console.log("Error during getNotifications:", e)
            }
            pushClientRoot.notificationReceived()
        }
    }

    Component.onCompleted: {
        try {
            pushClient.getNotifications()
        } catch(e) {
            console.log("Error getting notifications on start:", e)
        }
        checkAndStoreToken()
    }
}
