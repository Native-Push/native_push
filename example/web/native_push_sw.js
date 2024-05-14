"use strict";

importScripts("/localization.js", "/data_to_url.js")

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
    let {title, titleLocalizationKey, titleLocalizationArgs, body, bodyLocalizationKey, bodyLocalizationArgs, imageUrl} = event.data.json();

    const languages = navigator.languages;
    if (titleLocalizationKey) {
        title = localizations(languages, titleLocalizationKey, titleLocalizationArgs ?? []);
    }
    if (bodyLocalizationKey) {
        body = localizations(languages, bodyLocalizationKey, bodyLocalizationArgs ?? []);
    }

    return self.registration.showNotification(title, {
        body: body,
        image: imageUrl,
    });
});