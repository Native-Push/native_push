import 'package:flutter_test/flutter_test.dart';
import 'package:native_push/native_push.dart';
import 'package:native_push/src/native_push_method_channel.dart';
import 'package:native_push/src/native_push_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

final class MockNativePushPlatform
    extends NativePushPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<void> initialize({required final Map<String, String>? firebaseOptions, required final bool useDefaultNotificationChannel}) async {}

  @override
  Future<Map<String, String>?> initialNotification() async => null;

  @override
  Future<bool> registerForRemoteNotification({required final List<NotificationOption> options, required final String? vapidKey}) => Future.value(false);

  @override
  Future<(NotificationService, String?)> get notificationToken => Future.value((NotificationService.apns, '42'));

  @override
  Stream<(NotificationService, String?)> get notificationTokenStream => Stream.value((NotificationService.apns, '42'));

  @override
  Stream<Map<String, String>> get notificationStream => Stream.value({});
}

void main() {
  final initialPlatform = NativePushPlatform.instance;

  test('$MethodChannelNativePush is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNativePush>());
  });

  test('getPlatformVersion', () async {
    const nativePushPlugin = NativePush.instance;
    final fakePlatform = MockNativePushPlatform();
    NativePushPlatform.instance = fakePlatform;

    expect(await nativePushPlugin.notificationToken, '42');
  });
}
