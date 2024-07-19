package com.opdehipt.native_push

import android.Manifest
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import com.google.firebase.Firebase
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import com.google.firebase.initialize
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import org.json.JSONObject
import kotlin.coroutines.Continuation
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

/**
 * Plugin class for handling native push notifications in a Flutter application.
 */
class NativePushPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {

  companion object {
    private const val NOTIFICATION_PERMISSION_REQUEST_CODE = 1
    private var channel: MethodChannel? = null
    internal var mainActivityClass: Class<out Activity>? = null
      private set

    /**
     * Passes the new notification token to the Flutter side.
     *
     * @param token The new FCM token.
     */
    internal fun newToken(token: String) {
      Handler(Looper.getMainLooper()).post {
        channel?.invokeMethod("newNotificationToken", token)
      }
    }

    /**
     * Parses the notification data from the given intent and sends it to the Flutter side.
     *
     * @param intent The intent containing notification data.
     */
    private fun newNotification(intent: Intent) {
      val data = parseNotification(intent)
      channel?.invokeMethod("newNotification", data)
    }

    /**
     * Parses the notification data from the given intent.
     *
     * @param intent The intent containing notification data.
     * @return A map containing the notification data.
     */
    private fun parseNotification(intent: Intent?): Map<String, String> {
      val keys = (intent?.extras?.keySet() ?: emptyList())
      return if (keys.contains("native_push_data")) {
        val dataString = intent?.extras?.getString("native_push_data")
        val data = mutableMapOf<String, String>()
        if (dataString != null) {
          val jsonObject = JSONObject(dataString)
          val jsonKeys = jsonObject.keys()
          for (key in jsonKeys) {
            val value = jsonObject.getString(key)
            data[key] = value
          }
        }
        data
      }
      else {
        val filteredKeys = keys
          .filterNot { it.startsWith("google") || it.startsWith("gcm") || it in listOf("from", "collapse_key") }
        val data = mutableMapOf<String, String>()
        for (key in filteredKeys) {
          val value = intent?.extras?.getString(key) ?: continue
          data[key] = value
        }
        data
      }
    }
  }

  // The MethodChannel that will facilitate communication between Flutter and native Android
  private lateinit var channel: MethodChannel
  private lateinit var context: Context
  private var activity: Activity? = null
  private var continuation: Continuation<Boolean>? = null

  /**
   * Called when the plugin is attached to the Flutter engine.
   *
   * @param flutterPluginBinding The binding that provides the Flutter engine context.
   */
  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.opdehipt.native_push")
    channel.setMethodCallHandler(this)
    NativePushPlugin.channel = channel
  }

  /**
   * Called when a method is invoked on the MethodChannel.
   *
   * @param call The method call.
   * @param result The result of the method call.
   */
  override fun onMethodCall(call: MethodCall, result: Result) {
    CoroutineScope(Dispatchers.Main).launch {
      try {
        when (call.method) {
          "initialize" -> {
            initialize(call.arguments as Map<String, Any>)
            result.success(null)
          }
          "getInitialNotification" -> result.success(getInitialNotification())
          "registerForRemoteNotification" -> result.success(registerForRemoteNotification())
          "getNotificationToken" -> result.success(getNotificationToken())
          else -> result.notImplemented()
        }
      }
      catch (e: Exception) {
        result.error("native_push_error", null, e)
      }
    }
  }

  /**
   * Called when the plugin is detached from the Flutter engine.
   *
   * @param binding The binding that provided the Flutter engine context.
   */
  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  /**
   * Handles the result of a permission request.
   *
   * @param code The request code.
   * @param permissions The requested permissions.
   * @param grantResults The grant results for the corresponding permissions.
   * @return True if the request code matches, false otherwise.
   */
  override fun onRequestPermissionsResult(code: Int, permissions: Array<out String>, grantResults: IntArray) =
    when (code) {
      NOTIFICATION_PERMISSION_REQUEST_CODE -> {
        continuation?.resume(grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)
        continuation = null
        true
      }
      else -> false
    }

  /**
   * Called when the plugin is attached to an activity.
   *
   * @param binding The binding that provides the activity context.
   */
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    mainActivityClass = activity?.javaClass
    binding.addOnNewIntentListener {
      newNotification(it)
      false
    }
    binding.addRequestPermissionsResultListener(this)
  }

  /**
   * Called when the plugin is reattached to an activity for configuration changes.
   *
   * @param binding The binding that provides the activity context.
   */
  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding)
  }

  /**
   * Called when the plugin is detached from an activity.
   */
  override fun onDetachedFromActivity() {
    activity = null
  }

  /**
   * Called when the plugin is detached from an activity for configuration changes.
   */
  override fun onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity()
    NativePushPlugin.channel = null
  }

  /**
   * Initializes the plugin with the provided parameters.
   *
   * @param params The initialization parameters.
   */
  private suspend fun initialize(params: Map<String, Any>) {
    withContext(Dispatchers.Main) {
      if (FirebaseApp.getApps(context).isEmpty()) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && (params["useDefaultNotificationChannel"] as Boolean)) {
          val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
          notificationManager?.createNotificationChannel(
            NotificationChannel(
              "native_push_notification_channel",
              "Default Notification Channel",
              NotificationManager.IMPORTANCE_DEFAULT,
            ),
          )
        }
        val firebaseOptions = params["firebaseOptions"] as Map<String, String>
        val options = FirebaseOptions.Builder()
          .setProjectId(firebaseOptions["projectId"])
          .setApplicationId(firebaseOptions["applicationId"]!!)
          .setApiKey(firebaseOptions["apiKey"]!!)
          .build()
        Firebase.initialize(context, options)
      }
    }
  }

  /**
   * Retrieves the initial notification data if available.
   *
   * @return A map containing the initial notification data.
   */
  private fun getInitialNotification(): Map<String, String> = parseNotification(activity?.intent)

  /**
   * Registers for remote notifications, requesting permissions if necessary.
   *
   * @return True if registration was successful, false otherwise.
   */
  private suspend fun registerForRemoteNotification() =
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      val status = ActivityCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS)
      when (status) {
        PackageManager.PERMISSION_GRANTED -> {
          true
        }
        PackageManager.PERMISSION_DENIED -> {
          false
        }
        else -> {
          val activity = activity
          if (activity == null) {
            false
          }
          else {
            ActivityCompat.requestPermissions(
              activity,
              arrayOf(Manifest.permission.POST_NOTIFICATIONS),
              NOTIFICATION_PERMISSION_REQUEST_CODE,
            )
            withContext(Dispatchers.IO) {
              suspendCoroutine { continuation ->
                this@NativePushPlugin.continuation = continuation
              }
            }
          }
        }
      }
    }
    else {
      true
    }

  /**
   * Retrieves the current FCM notification token.
   *
   * @return The current FCM token.
   */
  private suspend fun getNotificationToken() =
    withContext(Dispatchers.IO) {
      FirebaseMessaging.getInstance().token.await()
    }
}
