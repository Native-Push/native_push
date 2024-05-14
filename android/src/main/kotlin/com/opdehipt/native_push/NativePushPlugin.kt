package com.opdehipt.native_push

import android.Manifest
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import com.google.firebase.Firebase
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

/** NativePushPlugin */
class NativePushPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
  companion object {
    private const val NOTIFICATION_PERMISSION_REQUEST_CODE = 1
    private var channel: MethodChannel? = null
    internal var mainActivityClass: Class<out Activity>? = null
      private set

    internal fun newToken(token: String) {
      channel?.invokeMethod("newNotificationToken", token)
    }

    private fun newNotification(intent: Intent) {
      val data = parseNotification(intent)
      channel?.invokeMethod("newNotification", data)
    }

    private fun parseNotification(intent: Intent?): Map<String, String> {
      val keys = (intent?.extras?.keySet() ?: emptyList())
      return if (keys.contains("native_push_data")) {
        val dataString = intent?.getStringExtra("native_push_data")
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
          val value = intent?.getStringExtra(key) ?: continue
          data[key] = value
        }
        data
      }
    }
  }

  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var context : Context
  private var activity : Activity? = null
  private var continuation: Continuation<Boolean>? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.opdehipt.native_push")
    channel.setMethodCallHandler(this)
    NativePushPlugin.channel = channel
  }

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
      catch (e : Exception) {
        result.error("native_push_error", null, e)
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onRequestPermissionsResult(code: Int, permissions: Array<out String>, grantResults: IntArray) =
    when (code) {
      NOTIFICATION_PERMISSION_REQUEST_CODE -> {
        continuation?.resume(grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)
        continuation = null
        true
      }
      else -> false
    }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    mainActivityClass = activity?.javaClass
    binding.addOnNewIntentListener {
      newNotification(it)
      false
    }
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding)
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity()
    NativePushPlugin.channel = null
  }

  private suspend fun initialize(params: Map<String, Any>) {
    withContext(Dispatchers.Main) {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && (params["useDefaultNotificationChannel"] as Boolean)) {
          val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
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
        .build()
      Firebase.initialize(context, options)
    }
  }

  private fun getInitialNotification(): Map<String, String> = parseNotification(activity?.intent)

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

  private suspend fun getNotificationToken() =
    withContext(Dispatchers.IO) {
      FirebaseMessaging.getInstance().token.await()
    }
}
