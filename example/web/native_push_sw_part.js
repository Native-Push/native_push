"use strict";

importScripts("/localization.js");

self.onpush = (event) => {
    let {
        title,
        titleLocalizationKey,
        titleLocalizationArgs,
        body, bodyLocalizationKey,
        bodyLocalizationArgs,
        image,
        ...data
    } = event.data.json();

    const languages = navigator.languages;
    if (titleLocalizationKey) {
        title = localization(languages, titleLocalizationKey, titleLocalizationArgs ?? []);
    }
    if (bodyLocalizationKey) {
        body = localization(languages, bodyLocalizationKey, bodyLocalizationArgs ?? []);
    }

    event.waitUntil(self.registration.showNotification(title, {
        body,
        image,
        data,
    }));
};
