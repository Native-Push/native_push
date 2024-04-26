import 'dart:js_interop';

import 'package:flutter/cupertino.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:native_push/src/native_push_platform_interface.dart';
import 'package:native_push/src/notification_service.dart';

@JS('native_push_initializeRemoteNotification')
external JSPromise _initialize();

@JS('native_push_registerForRemoteNotification')
external JSPromise<JSBoolean> _registerForRemoteNotification();

@JS('native_push_getNotificationToken')
external String? _getNotificationToken();

/// A web implementation of the NativePushPlatform of the NativePush plugin.
@immutable
final class NativePushWeb extends NativePushPlatform {
  /// Constructs a NativePushWeb
  NativePushWeb();

  static void registerWith(final Registrar registrar) {
    NativePushPlatform.instance = NativePushWeb();
  }

  @override
  Future<void> initialize() async {
    await _initialize().toDart;
  }

  @override
  Future<bool> registerForRemoteNotification() async {
    final success = await _registerForRemoteNotification().toDart;
    return success.toDart;
  }

  @override
  Future<(NotificationService, String?)> get notificationToken async =>
    (NotificationService.webPush, _getNotificationToken());

  @override
  Stream<(NotificationService, String?)> get notificationTokenStream => const Stream.empty();
}
