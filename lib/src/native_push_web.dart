import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/cupertino.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:native_push/src/native_push_platform_interface.dart';
import 'package:native_push/src/notification_option.dart';
import 'package:native_push/src/notification_service.dart';

@JS('native_push_initializeRemoteNotification')
external JSPromise _initialize(final JSFunction newNotificationCallback);

@JS('native_push_getInitialNotification')
external JSObject? _getInitialNotification();

@JS('native_push_registerForRemoteNotification')
external JSPromise<JSBoolean> _registerForRemoteNotification(final JSString vapidKey);

@JS('native_push_getNotificationToken')
external JSString? _getNotificationToken();

/// A web implementation of the NativePushPlatform of the NativePush plugin.
@immutable
final class NativePushWeb extends NativePushPlatform {
  static void registerWith(final Registrar registrar) {
    NativePushPlatform.instance = NativePushWeb();
  }

  final _notificationStreamController = StreamController<Map<String, String>>();

  @override
  Future<void> initialize({required final Map<String, String>? firebaseOptions, required final bool useDefaultNotificationChannel}) async {
    await _initialize(_newNotification.toJS).toDart;
  }

  void _newNotification(final JSObject object) {
    final data = (object.dartify()! as Map)
        .map((final key, final value) => MapEntry(key as String, value as String));
    _notificationStreamController.add(data);
  }

  @override
  Future<Map<String, String>?> initialNotification() async {
    final data = _getInitialNotification().dartify() as Map?;
    return data?.map((final key, final value) => MapEntry(key as String, value as String));
  }

  @override
  Future<bool> registerForRemoteNotification({required final List<NotificationOption> options, required final String? vapidKey}) async {
    if (vapidKey == null) {
      throw ArgumentError('Vapid key must be specified when using native push on the web.');
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
  Stream<Map<String, String>> get notificationStream => _notificationStreamController.stream;
}
