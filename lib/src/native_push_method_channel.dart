import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:native_push/src/native_push_platform_interface.dart';
import 'package:native_push/src/notification_option.dart';
import 'package:native_push/src/notification_service.dart';

/// An implementation of [NativePushPlatform] that uses method channels to interact with native code.
@immutable
final class MethodChannelNativePush extends NativePushPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('com.opdehipt.native_push');

  // Stream controllers to handle notification tokens and incoming notifications.
  final _tokenStreamController = StreamController<(NotificationService, String?)>();
  final _notificationStreamController = StreamController<Map<String, String>>();

  /// Initializes the push notification service.
  ///
  /// [firebaseOptions] - Configuration options for Firebase.
  /// [useDefaultNotificationChannel] - Whether to use the default notification channel.
  @override
  Future<void> initialize({required final Map<String, String>? firebaseOptions, required final bool useDefaultNotificationChannel}) async {
    // Sets up a method call handler to listen for method calls from the native platform.
    methodChannel.setMethodCallHandler((final call) async {
      switch (call.method) {
        case 'newNotificationToken':
          // Adds a new notification token to the token stream.
          _tokenStreamController.add((_notificationService, call.arguments));
          break;
        case 'newNotification':
          // Adds a new notification to the notification stream.
          _notificationStreamController.add(_convertNotification(call.arguments));
          break;
        default:
          // Handles any other method calls that are not explicitly managed.
          throw MissingPluginException('Not implemented: ${call.method}');
      }
    });

    // Invokes the initialize method on the native platform.
    await methodChannel.invokeMethod('initialize', {'firebaseOptions': firebaseOptions, 'useDefaultNotificationChannel': useDefaultNotificationChannel});
  }

  /// Gets the initial notification if the app was opened from a notification.
  ///
  /// Returns a Future that resolves to a map of the notification data, or null if there is no initial notification.
  @override
  Future<Map<String, String>?> initialNotification() async {
    // Gets the initial notification data from the native platform.
    final notification = await methodChannel.invokeMethod('getInitialNotification');
    if (notification != null) {
      return _convertNotification(notification);
    }
    return null;
  }

  Map<String, String> _convertNotification(final Map notification) => notification.map((final key, final value) => MapEntry(key as String, value as String));

  /// Registers for remote notifications.
  ///
  /// [options] - A list of notification options to configure the registration.
  /// [vapidKey] - Optional VAPID key for web push notifications.
  /// Returns a Future that resolves to a boolean indicating whether the registration was successful.
  @override
  Future<bool> registerForRemoteNotification({required final List<NotificationOption> options, required final String? vapidKey}) async {
    // Registers for remote notifications with the specified options.
    final arguments = options.map((final option) => option.name).toList();
    return await methodChannel.invokeMethod<bool>('registerForRemoteNotification', arguments) ?? false;
  }

  /// Gets the current notification token.
  ///
  /// Returns a Future that resolves to a tuple containing the notification service and the token, or null if no token is available.
  @override
  Future<(NotificationService, String?)> get notificationToken async {
    // Gets the current notification token from the native platform.
    final token = await methodChannel.invokeMethod<String>('getNotificationToken');
    return (_notificationService, token);
  }

  /// A stream that provides updates to the notification token.
  ///
  /// Each event in the stream is a tuple containing the notification service and the token, or null if no token is available.
  @override
  Stream<(NotificationService, String?)> get notificationTokenStream => _tokenStreamController.stream;

  /// A stream that provides incoming notifications.
  ///
  /// Each event in the stream is a map containing the notification data.
  @override
  Stream<Map<String, String>> get notificationStream => _notificationStreamController.stream;

  // Determines the notification service based on the platform.
  @pragma('vm:platform-const')
  static final _notificationService = () {
    if (Platform.isAndroid) {
      return NotificationService.fcm;
    }
    else if (Platform.isIOS || Platform.isMacOS) {
      return NotificationService.apns;
    }
    else {
      return NotificationService.unknown;
    }
  }();
}
