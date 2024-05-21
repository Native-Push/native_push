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

// Event listener for the installation of the service worker
self.oninstall = event => {
    // Ensures the new service worker activates immediately, bypassing the waiting state
    event.waitUntil(self.skipWaiting());
};

// Event listener for the activation of the service worker
self.onactivate = (event) => {
    // Ensures that the service worker takes control of all clients as soon as it activates
    event.waitUntil(self.clients.claim());
};

// Event listener for when a notification is clicked
self.onnotificationclick = (event) => {
    // Close the notification pop-up
    event.notification.close();

    // Ensure that the actions within are completed before the service worker terminates
    event.waitUntil(
        // Fetches all the clients (open windows) controlled by this service worker
        self.clients.matchAll({
            type: "window",
        })
        .then(async (clientList) => {
            const data = event.notification.data;
            if (data) {
                // If there are any open windows
                if (clientList.length !== 0) {
                    // Focus the first client window
                    const client = clientList[0];
                    await client.focus();
                    // Send a message to the client window with the notification data
                    client.postMessage({ type: "native_push_newNotification", data: data });
                }
                else {
                    // If no windows are open, create a base64 encoded URL fragment from the data
                    const dataBase64 = btoa(JSON.stringify(data))
                        .replace("+", '-')
                        .replace("/", '_')
                        .replace("=", '');
                    // Open a new window/tab with the URL containing the encoded data
                    await self.clients.openWindow(`/#${dataBase64}`);
                }
            }
        }),
    );
};
