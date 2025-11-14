let native_push_newNotificationCallback;

const href = location.href;
if (href.includes("#")) {
    const parts = href.split("#");
    const base64InitialNotification = parts[1];
    const padding = 4 - base64InitialNotification.length % 4;
    native_push_initialNotification = JSON.parse(atob(
        base64InitialNotification
            .replace("-", "+")
            .replace("_", '/')
            .padEnd(base64InitialNotification.length + (padding % 4), "=")
    ));
    history.replaceState(null, "", parts[0])
}

async function native_push_initializeRemoteNotification(newNotificationCallback) {
    native_push_newNotificationCallback = newNotificationCallback;
    await navigator.serviceWorker.register('/native_push_sw.js');
    navigator.serviceWorker.onmessage = (event) => {
        switch (event.data?.type) {
            case "native_push_newNotification":
                if (native_push_newNotificationCallback) {
                    native_push_newNotificationCallback(event.data?.data);
                }
                break;
        }
    }
}

async function native_push_registerForRemoteNotification(vapidKey) {
    function base64ToArray(base64) {
        const binaryString = atob(base64);
        const bytes = new Uint8Array(binaryString.length);
        for (let i = 0; i < binaryString.length; i++) {
            bytes[i] = binaryString.charCodeAt(i);
        }
        return bytes;
    }

    const status = await Notification.requestPermission();
    if (status === 'granted') {
        const registration = await navigator.serviceWorker.ready;
        const subscription = await registration.pushManager.subscribe({
            userVisibleOnly: true,
            applicationServerKey: base64ToArray(vapidKey)
        });
        const json = subscription.toJSON()
        const payload = {
            "endpoint": json.endpoint,
            "p256dh": json.keys["p256dh"],
            "auth": json.keys["auth"],
        }
        window.localStorage.setItem('native_push_token', JSON.stringify(payload));
        return true;
    }
    else {
        return false;
    }
}