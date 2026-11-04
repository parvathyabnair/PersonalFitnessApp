import QtQuick 2.7
import Ubuntu.PushNotifications 0.1

Item {
    id: pushClientRoot
    signal notificationReceived(var notification)

    PushClient {
        id: pushClient
        appId: "personalfitnessapp.parvathy_personalfitnessapp"

        onTokenChanged: {
            console.log("Push notification registration token:", pushClient.token)
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
    }
}

