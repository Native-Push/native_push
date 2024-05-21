"use strict";

// Event listener for when a push message is received
self.onpush = (event) => {
    // Destructure the incoming push message payload into separate variables
    let {
        title,                    // Notification title
        titleLocalizationKey,     // Localization key for the title (not used here)
        titleLocalizationArgs,    // Localization arguments for the title (not used here)
        body,                     // Notification body text
        bodyLocalizationKey,      // Localization key for the body (not used here)
        bodyLocalizationArgs,     // Localization arguments for the body (not used here)
        image,                    // URL of an image to display in the notification
        ...data     // Remaining data to be stored in the notification's data attribute
    } = event.data.json();        // Parse the incoming data as JSON

    // Ensure that the actions within are completed before the service worker terminates
    event.waitUntil(
        // Show a notification with the specified title, body, image, and additional data
        self.registration.showNotification(title, {
            body,
            image,
            data,
        })
    );
};
