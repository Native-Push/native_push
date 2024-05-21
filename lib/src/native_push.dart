import 'package:flutter/cupertino.dart';
import 'package:native_push/src/native_push_platform_interface.dart';
import 'package:native_push/src/notification_option.dart';
import 'package:native_push/src/notification_service.dart';

/// A class to manage native push notifications.
@immutable
final class NativePush {
  // Factory constructor to return the singleton instance of NativePush.
  factory NativePush() => instance;

  // Private constant constructor to ensure NativePush is only instantiated once.
  const NativePush._();

  // Singleton instance of NativePush.
  static const instance = NativePush._();

  /// Initializes the push notification service.
  ///
  /// [firebaseOptions] - Optional configuration for Firebase.
  /// [useDefaultNotificationChannel] - Whether to use the default notification channel.
  /// Returns a Future that completes when initialization is done.
  Future<void> initialize({final Map<String, String>? firebaseOptions, final bool useDefaultNotificationChannel = false}) =>
      NativePushPlatform.instance.initialize(firebaseOptions: firebaseOptions, useDefaultNotificationChannel: useDefaultNotificationChannel);

  /// Gets the initial notification data if the app was opened from a notification.
  ///
  /// Returns a Future that resolves to a map of the notification data, or null if there is no initial notification.
  Future<Map<String, String>?> initialNotification() async => NativePushPlatform.instance.initialNotification();

  /// Registers for remote notifications.
  ///
  /// [options] - A list of notification options to configure the registration.
  /// [vapidKey] - Optional VAPID key for web push notifications.
  /// Returns a Future that resolves to a boolean indicating whether the registration was successful.
  Future<bool> registerForRemoteNotification({required final List<NotificationOption> options, final String? vapidKey}) =>
      NativePushPlatform.instance.registerForRemoteNotification(options: options, vapidKey: vapidKey);

  /// Gets the current notification token.
  ///
  /// Returns a Future that resolves to a tuple containing the notification service and the token, or null if no token is available.
  Future<(NotificationService, String?)> get notificationToken => NativePushPlatform.instance.notificationToken;

  /// A stream that provides updates to the notification token.
  ///
  /// Each event in the stream is a tuple containing the notification service and the token, or null if no token is available.
  Stream<(NotificationService, String?)> get notificationTokenStream => NativePushPlatform.instance.notificationTokenStream;

  /// A stream that provides incoming notifications.
  ///
  /// Each event in the stream is a map containing the notification data.
  Stream<Map<String, String>> get notificationStream => NativePushPlatform.instance.notificationStream;
}
