import 'package:flutter/cupertino.dart';
import 'package:native_push/src/native_push_method_channel.dart';
import 'package:native_push/src/notification_option.dart';
import 'package:native_push/src/notification_service.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// An abstract base class for native push notification platform interface.
@immutable
abstract base class NativePushPlatform extends PlatformInterface {
  /// Constructs a NativePushPlatform.
  ///
  /// This constructor initializes the platform interface with a unique token.
  NativePushPlatform() : super(token: _token);

  /// A unique token used to verify the platform instance.
  static final Object _token = Object();

  /// The default instance of [NativePushPlatform] to use.
  ///
  /// Defaults to [MethodChannelNativePush].
  static NativePushPlatform _instance = MethodChannelNativePush();

  /// Gets the current instance of [NativePushPlatform].
  ///
  /// Returns the default instance, which is [MethodChannelNativePush].
  static NativePushPlatform get instance => _instance;

  /// Sets a new instance of [NativePushPlatform].
  ///
  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NativePushPlatform] when
  /// they register themselves.
  static set instance(final NativePushPlatform instance) {
    // Verifies that the instance is using the correct token.
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Initializes the push notification service.
  ///
  /// [firebaseOptions] - Configuration options for Firebase.
  /// [useDefaultNotificationChannel] - Whether to use the default notification channel.
  /// This method should be implemented by the platform-specific subclass.
  Future<void> initialize(
      {required final Map<String, String>? firebaseOptions,
      required final bool useDefaultNotificationChannel});

  /// Gets the initial notification if the app was opened from a notification.
  ///
  /// Returns a Future that resolves to a map of the notification data, or null if there is no initial notification.
  /// This method should be implemented by the platform-specific subclass.
  Future<Map<String, String>?> initialNotification();

  /// Registers for remote notifications.
  ///
  /// [options] - A list of notification options to configure the registration.
  /// [vapidKey] - Optional VAPID key for web push notifications.
  /// Returns a Future that resolves to a boolean indicating whether the registration was successful.
  /// This method should be implemented by the platform-specific subclass.
  Future<bool> registerForRemoteNotification(
      {required final List<NotificationOption> options,
      required final String? vapidKey});

  /// Gets the current notification token.
  ///
  /// Returns a Future that resolves to a tuple containing the notification service and the token, or null if no token is available.
  /// This method should be implemented by the platform-specific subclass.
  Future<(NotificationService, String?)> get notificationToken;

  /// A stream that provides updates to the notification token.
  ///
  /// Each event in the stream is a tuple containing the notification service and the token, or null if no token is available.
  /// This property should be implemented by the platform-specific subclass.
  Stream<(NotificationService, String?)> get notificationTokenStream;

  /// A stream that provides incoming notifications.
  ///
  /// Each event in the stream is a map containing the notification data.
  /// This property should be implemented by the platform-specific subclass.
  Stream<Map<String, String>> get notificationStream;
}
