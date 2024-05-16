"use strict";

self.onpush = (event) => {
    let {
        title,
        titleLocalizationKey,
        titleLocalizationArgs,
        body,
        bodyLocalizationKey,
        bodyLocalizationArgs,
        image,
        ...data
    } = event.data.json();

    event.waitUntil(self.registration.showNotification(title, {
        body,
        image,
        data,
    }));
};
