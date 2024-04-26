package com.opdehipt.native_push

import com.google.firebase.messaging.FirebaseMessagingService

class NativePushFirebaseMessagingService : FirebaseMessagingService() {
    override fun onNewToken(token: String) {
        NativePushPlugin.newToken(token)
    }
}