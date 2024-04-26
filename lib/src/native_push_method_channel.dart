import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:native_push/src/native_push_platform_interface.dart';
import 'package:native_push/src/notification_service.dart';

/// An implementation of [NativePushPlatform] that uses method channels.
@immutable
final class MethodChannelNativePush extends NativePushPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('com.opdehipt.native_push');

  final _tokenStreamController = StreamController<(NotificationService, String?)>();

  @override
  Future<void> initialize() async {
    methodChannel.setMethodCallHandler((final call) async {
      switch (call.method) {
        case 'newNotificationToken':
          _tokenStreamController.add((_notificationService, call.arguments));
      }
    });
    if (Platform.isAndroid) {
      await methodChannel.invokeMethod('initialize');
    }
  }

  @override
  Future<bool> registerForRemoteNotification() async =>
    await methodChannel.invokeMethod<bool>('registerForRemoteNotification') ?? false;

  @override
  Future<(NotificationService, String?)> get notificationToken async {
    final token = await methodChannel.invokeMethod<String>('getNotificationToken');
    return (_notificationService, token);
  }

  @override
  Stream<(NotificationService, String?)> get notificationTokenStream => _tokenStreamController.stream;

  @pragma('vm:platform-const-if', !kDebugMode)
  static NotificationService get _notificationService =>
    switch (defaultTargetPlatform) {
      TargetPlatform.android => NotificationService.fcm,
      TargetPlatform.iOS || TargetPlatform.macOS => NotificationService.apns,
      TargetPlatform.windows || TargetPlatform.linux || TargetPlatform.fuchsia  => NotificationService.unknown,
    };
}
