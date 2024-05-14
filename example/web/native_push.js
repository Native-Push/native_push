async function native_push_initializeRemoteNotification() {
    await navigator.serviceWorker.register('/native_push_sw.js');
}

async function native_push_registerForRemoteNotification(vapidKey) {
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

function base64ToArray(base64) {
    const binaryString = atob(base64);
    const bytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i);
    }
    return bytes;
}