import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/cupertino.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:native_push/src/native_push_platform_interface.dart';
import 'package:native_push/src/notification_option.dart';
import 'package:native_push/src/notification_service.dart';
import 'package:web/web.dart' as web;

/// External JavaScript function to initialize remote notifications.
@JS('native_push_initializeRemoteNotification')
external JSPromise _initialize(final JSFunction newNotificationCallback);

/// External JavaScript object to get the initial notification.
@JS('native_push_initialNotification')
external JSObject? _initialNotification;

/// External JavaScript function to register for remote notifications.
@JS('native_push_registerForRemoteNotification')
external JSPromise<JSBoolean> _registerForRemoteNotification(final JSString vapidKey);

/// A web implementation of the NativePushPlatform of the NativePush plugin.
@immutable
final class NativePushWeb extends NativePushPlatform {
  /// Registers this class as the default instance of [NativePushPlatform].
  static void registerWith(final Registrar registrar) {
    NativePushPlatform.instance = NativePushWeb();
  }

  /// Stream controller for incoming notifications.
  final _notificationStreamController = StreamController<Map<String, String>>();

  @override
  Future<void> initialize({required final Map<String, String>? firebaseOptions, required final bool useDefaultNotificationChannel}) async {
    // Initializes the native push notification system.
    final script = web.window.document.createElement('script') as web.HTMLScriptElement
      ..src = '/native_push.js';
    web.window.document.head?.appendChild(script);
    await script.onLoad.first;
    await _initialize(_newNotification.toJS).toDart;
  }

  /// Callback function to handle new notifications.
  void _newNotification(final JSObject object) {
    final data = (object.dartify()! as Map)
        .map((final key, final value) => MapEntry(key as String, value as String));
    _notificationStreamController.add(data);
  }

  @override
  Future<Map<String, String>?> initialNotification() async {
    // Gets the initial notification if the app was opened from a notification.
    final data = _initialNotification.dartify() as Map?;
    return data?.map((final key, final value) => MapEntry(key as String, value as String));
  }

  @override
  Future<bool> registerForRemoteNotification({required final List<NotificationOption> options, required final String? vapidKey}) async {
    // Registers for remote notifications using the VAPID key.
    if (vapidKey == null) {
      throw ArgumentError('Vapid key must be specified when using native push on the web.');
    }
    final success = await _registerForRemoteNotification(vapidKey.toJS).toDart;
    return success.toDart;
  }

  @override
  Future<(NotificationService, String?)> get notificationToken async {
    // Gets the notification token from the browser's local storage.
    final token = web.window.localStorage.getItem('native_push_token');
    return (NotificationService.webPush, token);
  }

  @override
  Stream<(NotificationService, String?)> get notificationTokenStream => const Stream.empty();

  @override
  Stream<Map<String, String>> get notificationStream => _notificationStreamController.stream;
}
