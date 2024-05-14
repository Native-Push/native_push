import 'package:flutter/cupertino.dart';
import 'package:native_push/src/native_push_method_channel.dart';
import 'package:native_push/src/notification_option.dart';
import 'package:native_push/src/notification_service.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

@immutable
abstract base class NativePushPlatform extends PlatformInterface {
  /// Constructs a NativePushPlatform.
  NativePushPlatform() : super(token: _token);

  static final Object _token = Object();

  static NativePushPlatform _instance = MethodChannelNativePush();

  /// The default instance of [NativePushPlatform] to use.
  ///
  /// Defaults to [MethodChannelNativePush].
  static NativePushPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NativePushPlatform] when
  /// they register themselves.
  static set instance(final NativePushPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  Future<void> initialize({required final Map<String, String>? firebaseOptions, required final bool useDefaultNotificationChannel});
  Future<Map<String, String>?> initialNotification();
  Future<bool> registerForRemoteNotification({required final List<NotificationOption> options, required final String? vapidKey});
  Future<(NotificationService, String?)> get notificationToken;
  Stream<(NotificationService, String?)> get notificationTokenStream;
  Stream<Map<String, String>> get notificationStream;
}
