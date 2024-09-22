package com.opdehipt.native_push

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Build.VERSION_CODES
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import org.json.JSONObject
import java.net.URL
import java.util.*

/**
 * Service for handling Firebase push notifications.
 */
open class NativePushFirebaseMessagingService : FirebaseMessagingService() {

    /**
     * The notification channel ID for this service.
     */
    protected open val notificationChannelId = "native_push_notification_channel"

    /**
     * Called when a new token for the default Firebase project is generated.
     *
     * @param token The new token.
     */
    override fun onNewToken(token: String) {
        NativePushPlugin.newToken(token)
    }

    /**
     * Called when a message is received from Firebase Cloud Messaging.
     *
     * @param message The received remote message.
     */
    @SuppressLint("DiscouragedApi")
    override fun onMessageReceived(message: RemoteMessage) {
        // Retrieve application metadata to get default notification settings
        val applicationInfo = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
        val defaultNotificationChannel = applicationInfo.metaData
            .getString("com.google.firebase.messaging.default_notification_channel_id")!!

        // Build the notification using NotificationCompat
        val notificationBuilder = NotificationCompat.Builder(
            this,
            message.notification?.channelId ?: defaultNotificationChannel,
        )
            .setAutoCancel(true)

        // Define the intent that will be triggered when the user taps the notification
        val mainActivityClass = NativePushPlugin.mainActivityClass
        if (mainActivityClass != null) {
            val intent = Intent(this, mainActivityClass)
            intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            intent.identifier = message.messageId ?: UUID.randomUUID().toString()
            intent.putExtra("native_push_data", JSONObject(message.data as Map<*, *>).toString())
            intent.action = "com.opdehipt.native_push.PUSH"
            val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                intent,
                PendingIntent.FLAG_IMMUTABLE,
            )
            notificationBuilder.setContentIntent(pendingIntent)
        }

        // Set notification sound
        val sound = message.notification?.sound
        val soundUri = if (sound != null) {
            Uri.parse("android.resource://$packageName/$sound")
        }
        else {
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        }
        notificationBuilder.setSound(soundUri)

        // Set notification priority based on Android version
        if (Build.VERSION.SDK_INT >= VERSION_CODES.N) {
            notificationBuilder.setPriority(
                message.notification?.notificationPriority ?: NotificationManager.IMPORTANCE_DEFAULT
            )
        }
        else {
            notificationBuilder.setPriority(
                message.notification?.notificationPriority ?: Notification.PRIORITY_DEFAULT
            )
        }

        // Set notification title with localization support
        val localizedTitle = message.notification?.titleLocalizationKey
        val title = if (localizedTitle != null) {
            getString(
                resources.getIdentifier(localizedTitle, "string", packageName),
                message.notification?.titleLocalizationArgs,
            )
        }
        else {
            message.notification?.title
        }
        notificationBuilder.setContentTitle(title)

        // Set notification body with localization support
        val bodyTitle = message.notification?.bodyLocalizationKey
        val body = if (bodyTitle != null) {
            getString(
                resources.getIdentifier(bodyTitle, "string", packageName),
                message.notification?.bodyLocalizationArgs,
            )
        }
        else {
            message.notification?.body
        }
        notificationBuilder.setContentText(body)

        // Set notification icon
        val icon = message.notification?.icon
        if (icon != null) {
            notificationBuilder.setSmallIcon(resources.getIdentifier(icon, "drawable", packageName))
        }
        else {
            notificationBuilder.setSmallIcon(applicationInfo.metaData.getInt("com.google.firebase.messaging.default_notification_icon"))
        }

        // Set large notification icon if available
        val imageUrl = message.notification?.imageUrl
        if (imageUrl != null) {
            val image = BitmapFactory.decodeStream(URL(imageUrl.toString()).openConnection().getInputStream())
            notificationBuilder.setLargeIcon(image)
        }

        // Get the NotificationManager service and display the notification
        val notificationManager = getSystemService(NOTIFICATION_SERVICE) as? NotificationManager
        val notificationId = UUID.randomUUID().hashCode()
        notificationManager?.notify(notificationId, notificationBuilder.build())
    }
}
