import 'dart:js_interop';

import 'package:flutter/cupertino.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:native_push/src/native_push_platform_interface.dart';
import 'package:native_push/src/notification_option.dart';
import 'package:native_push/src/notification_service.dart';

@JS('native_push_initializeRemoteNotification')
external JSPromise _initialize();

@JS('native_push_registerForRemoteNotification')
external JSPromise<JSBoolean> _registerForRemoteNotification(final JSString vapidKey);

@JS('native_push_getNotificationToken')
external JSString? _getNotificationToken();

/// A web implementation of the NativePushPlatform of the NativePush plugin.
@immutable
final class NativePushWeb extends NativePushPlatform {
  /// Constructs a NativePushWeb
  NativePushWeb();

  static void registerWith(final Registrar registrar) {
    NativePushPlatform.instance = NativePushWeb();
  }

  @override
  Future<void> initialize({required final Map<String, String>? firebaseOptions, required final bool useDefaultNotificationChannel}) async {
    await _initialize().toDart;
  }

  @override
  Future<Map<String, String>?> initialNotification() async => null;

  @override
  Future<bool> registerForRemoteNotification({required final List<NotificationOption> options, required final String? vapidKey}) async {
    if (vapidKey == null) {
      throw Error(); // TODO(sven): replace with actual error
    }
    final success = await _registerForRemoteNotification(vapidKey.toJS).toDart;
    return success.toDart;
  }

  @override
  Future<(NotificationService, String?)> get notificationToken async =>
    (NotificationService.webPush, _getNotificationToken()?.toDart);

  @override
  Stream<(NotificationService, String?)> get notificationTokenStream => const Stream.empty();

  @override
  Stream<Map<String, String>> get notificationStream => const Stream.empty();
}
