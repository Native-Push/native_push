async function native_push_initializeRemoteNotification() {
    await navigator.serviceWorker.register('/native_push_sw.js');
}

async function native_push_registerForRemoteNotification() {
    const status = await Notification.requestPermission();
    if (status === 'granted') {
        const registration = await navigator.serviceWorker.ready;
        const subscription = await registration.pushManager.subscribe({userVisibleOnly: true});
        window.localStorage.setItem('native_push_subscriptionEndpoint', subscription.endpoint);
        return true;
    }
    else {
        return false;
    }
}

function native_push_getNotificationToken() {
    return window.localStorage.getItem('native_push_subscriptionEndpoint');
}