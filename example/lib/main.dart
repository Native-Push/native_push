import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:native_push/native_push.dart';

void main() {
  runApp(const MyApp());
}

@immutable
final class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

final class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _nativePushPlugin = NativePush();

  @override
  void initState() {
    super.initState();
    unawaited(initPlatformState());
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    NotificationService _;
    String? platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      (_, platformVersion) =
          await _nativePushPlugin.notificationToken;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return;
    }

    setState(() {
      _platformVersion = platformVersion ?? 'Unknown platform version';
    });
  }

  @override
  Widget build(final BuildContext context) =>
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
}
