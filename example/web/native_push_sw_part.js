"use strict";

// Import the localization script to handle localized strings
importScripts("/localization.js");

// Event listener for when a push message is received
self.onpush = (event) => {
    // Destructure the incoming push message payload into separate variables
    let {
        title,                      // Notification title
        titleLocalizationKey,       // Localization key for the title
        titleLocalizationArgs,      // Localization arguments for the title
        body,                       // Notification body text
        bodyLocalizationKey,        // Localization key for the body
        bodyLocalizationArgs,       // Localization arguments for the body
        image,                      // URL of an image to display in the notification
        ...data       // Remaining data to be stored in the notification's data attribute
    } = event.data.json();          // Parse the incoming data as JSON

    // Get the preferred languages of the user
    const languages = navigator.languages;

    // Localize the title if a localization key is provided
    if (titleLocalizationKey) {
        title = localization(languages, titleLocalizationKey, titleLocalizationArgs ?? []);
    }

    // Localize the body if a localization key is provided
    if (bodyLocalizationKey) {
        body = localization(languages, bodyLocalizationKey, bodyLocalizationArgs ?? []);
    }

    // Ensure that the actions within are completed before the service worker terminates
    event.waitUntil(
        // Show a notification with the localized title, body, image, and additional data
        self.registration.showNotification(title, {
            body,
            image,
            data,
        })
    );
};
