package com.opdehipt.native_push

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import com.google.firebase.Firebase
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
import kotlin.coroutines.Continuation
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

/** NativePushPlugin */
class NativePushPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
  internal companion object {
    private const val NOTIFICATION_PERMISSION_REQUEST_CODE = 1
    private var channel: MethodChannel? = null

    fun newToken(token: String) {
      channel?.invokeMethod("newNotificationToken", token)
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
            initialize()
            result.success(null)
          }
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

  private fun initialize() {
    Firebase.initialize(context)
  }

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
