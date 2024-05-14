"use strict";

importScripts("/data_to_url.js");

self.addEventListener('install', function(event) {
    event.waitUntil(self.skipWaiting());
});

self.addEventListener('activate', function(event) {
    event.waitUntil(self.clients.claim());
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  const url = dataToUrl(event.notification.data);
  event.waitUntil(clients.openWindow(url))
})

self.addEventListener('push', function(event) {
    let {title, body, imageUrl} = event.data.json();

    return self.registration.showNotification(title, {
        body: body,
        image: imageUrl,
    });
});