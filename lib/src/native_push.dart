import 'package:flutter/cupertino.dart';
import 'package:native_push/src/native_push_platform_interface.dart';
import 'package:native_push/src/notification_option.dart';
import 'package:native_push/src/notification_service.dart';

@immutable
final class NativePush {
  factory NativePush() => instance;
  const NativePush._();
  static const instance = NativePush._();

  Future<void> initialize({final Map<String, String>? firebaseOptions, final bool useDefaultNotificationChannel = false}) =>
      NativePushPlatform.instance.initialize(firebaseOptions: firebaseOptions, useDefaultNotificationChannel: useDefaultNotificationChannel);
  Future<Map<String, String>?> initialNotification() async => NativePushPlatform.instance.initialNotification();
  Future<bool> registerForRemoteNotification({required final List<NotificationOption> options, final String? vapidKey}) =>
      NativePushPlatform.instance.registerForRemoteNotification(options: options, vapidKey: vapidKey);
  Future<(NotificationService, String?)> get notificationToken => NativePushPlatform.instance.notificationToken;
  Stream<(NotificationService, String?)> get notificationTokenStream => NativePushPlatform.instance.notificationTokenStream;
  Stream<Map<String, String>> get notificationStream => NativePushPlatform.instance.notificationStream;
}
