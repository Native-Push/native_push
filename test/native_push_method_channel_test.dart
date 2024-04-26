import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_push/src/native_push_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelNativePush();
  const channel = MethodChannel('com.opdehipt.native_push');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (final methodCall) async => '42',
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getNotificationToken', () async {
    expect(await platform.notificationToken, '42');
  });
}
