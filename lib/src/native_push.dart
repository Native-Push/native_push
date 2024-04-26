import 'package:flutter/cupertino.dart';
import 'package:native_push/src/native_push_platform_interface.dart';
import 'package:native_push/src/notification_service.dart';

@immutable
final class NativePush {
  Future<void> initialize() => NativePushPlatform.instance.initialize();
  Future<bool> registerForRemoteNotification() => NativePushPlatform.instance.registerForRemoteNotification();
  Future<(NotificationService, String?)> get notificationToken => NativePushPlatform.instance.notificationToken;
  Stream<(NotificationService, String?)> get notificationTokenStream => NativePushPlatform.instance.notificationTokenStream;
}
