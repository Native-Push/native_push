"use strict";importScripts("/localization.js","/data_to_url.js"),self.addEventListener("install",function(i){i.waitUntil(self.skipWaiting())}),self.addEventListener("activate",function(i){i.waitUntil(self.clients.claim())}),self.addEventListener("notificationclick",function(i){i.notification.close();var t=dataToUrl(i.notification.data);i.waitUntil(clients.openWindow(t))}),self.addEventListener("push",function(i){let{title:t,titleLocalizationKey:a,titleLocalizationArgs:n,body:o,bodyLocalizationKey:e,bodyLocalizationArgs:l,imageUrl:s}=i.data.json();i=navigator.languages;return a&&(t=localizations(i,a,n??[])),e&&(o=localizations(i,e,l??[])),self.registration.showNotification(t,{body:o,image:s})});