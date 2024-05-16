import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:native_push/src/native_push_platform_interface.dart';
import 'package:native_push/src/notification_option.dart';
import 'package:native_push/src/notification_service.dart';

/// An implementation of [NativePushPlatform] that uses method channels.
@immutable
final class MethodChannelNativePush extends NativePushPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('com.opdehipt.native_push');

  final _tokenStreamController = StreamController<(NotificationService, String?)>();
  final _notificationStreamController = StreamController<Map<String, String>>();

  @override
  Future<void> initialize({required final Map<String, String>? firebaseOptions, required final bool useDefaultNotificationChannel}) async {
    methodChannel.setMethodCallHandler((final call) async {
      switch (call.method) {
        case 'newNotificationToken':
          _tokenStreamController.add((_notificationService, call.arguments));
        case 'newNotification':
          _notificationStreamController.add(_convertNotification(call.arguments));
      }
    });
    await methodChannel.invokeMethod('initialize', {'firebaseOptions': firebaseOptions, 'useDefaultNotificationChannel': useDefaultNotificationChannel});
  }

  @override
  Future<Map<String, String>?> initialNotification() async {
    final notification = await methodChannel.invokeMethod('getInitialNotification');
    if (notification != null) {
      return _convertNotification(notification);
    }
    return null;
  }

  Map<String, String> _convertNotification(final Map notification) => notification.map((final key, final value) => MapEntry(key as String, value as String));

  @override
  Future<bool> registerForRemoteNotification({required final List<NotificationOption> options, required final String? vapidKey}) async {
    final arguments = options.map((final option) => option.name).toList();
    return await methodChannel.invokeMethod<bool>('registerForRemoteNotification', arguments) ?? false;
  }

  @override
  Future<(NotificationService, String?)> get notificationToken async {
    final token = await methodChannel.invokeMethod<String>('getNotificationToken');
    return (_notificationService, token);
  }

  @override
  Stream<(NotificationService, String?)> get notificationTokenStream => _tokenStreamController.stream;

  @override
  Stream<Map<String, String>> get notificationStream => _notificationStreamController.stream;

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
