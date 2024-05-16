let native_push_newNotificationCallback;
let native_push_initialNotification;

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
    const href = window.location.href;
    if (href.includes("#")) {
        const base64InitialNotification = href.split("#")[1]
        const padding = 4 - base64InitialNotification.length % 4;
        native_push_initialNotification = JSON.parse(atob(
            base64InitialNotification
                .replace("-", "+")
                .replace("_", '/')
                .padEnd(base64InitialNotification.length + (padding === 4 ? 0 : padding), "=")
        ));
    }
}

function native_push_getInitialNotification() {
    return native_push_initialNotification;
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
        window.localStorage.setItem('native_push_subscriptionEndpoint', JSON.stringify(payload));
        return true;
    }
    else {
        return false;
    }
}

function native_push_getNotificationToken() {
    return window.localStorage.getItem('native_push_subscriptionEndpoint');
}