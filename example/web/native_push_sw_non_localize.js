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

self.oninstall = event => {
    event.waitUntil(self.skipWaiting());
};

self.onactivate = (event) => {
    event.waitUntil(self.clients.claim());
};

self.onnotificationclick = (event) => {
    event.notification.close();
    event.waitUntil(
        self.clients.matchAll({
            type: "window",
        })
        .then(async (clientList) => {
            const data = event.notification.data;
            if (data) {
                if (clientList.length !== 0) {
                    const client = clientList[0];
                    await client.focus();
                    client.postMessage({type: "native_push_newNotification", data: data});
                }
                else {
                    const dataBase64 = btoa(JSON.stringify(data))
                        .replace("+", '-')
                        .replace("/", '_')
                        .replace("=", '')
                    await self.clients.openWindow(`/#${dataBase64}`);
                }
            }
        }),
  );
};
