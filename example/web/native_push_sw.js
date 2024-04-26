"use strict";

self.addEventListener('install', function(event) {
    event.waitUntil(self.skipWaiting());
});

self.addEventListener('activate', function(event) {
    event.waitUntil(self.clients.claim());
});

self.addEventListener('notificationclick', function(event) {
    let url;
    if (event.notification.data.click_action) {
        url = event.notification.data.click_action;
    } else {
        url = event.currentTarget.origin;
    }
    self.clients.openWindow(url).then(function () {
        event.notification.close();
    });
});


self.addEventListener('push', function(event) {
    const {title, body, icon} = event.data;

    return self.registration.showNotification(title, {
        body: body,
        icon: icon,
    });
});