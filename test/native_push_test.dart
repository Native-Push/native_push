import 'package:flutter_test/flutter_test.dart';
import 'package:native_push/native_push.dart';
import 'package:native_push/src/native_push_method_channel.dart';
import 'package:native_push/src/native_push_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

final class MockNativePushPlatform
    extends NativePushPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> registerForRemoteNotification() => Future.value(false);

  @override
  Future<(NotificationService, String?)> get notificationToken => Future.value((NotificationService.apns, '42'));

  @override
  Stream<(NotificationService, String?)> get notificationTokenStream => Stream.value((NotificationService.apns, '42'));
}

void main() {
  final initialPlatform = NativePushPlatform.instance;

  test('$MethodChannelNativePush is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNativePush>());
  });

  test('getPlatformVersion', () async {
    final nativePushPlugin = NativePush();
    final fakePlatform = MockNativePushPlatform();
    NativePushPlatform.instance = fakePlatform;

    expect(await nativePushPlugin.notificationToken, '42');
  });
}
