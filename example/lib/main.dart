import 'dart:io';

import 'package:flutter/material.dart';
import 'package:native_push/native_push.dart';

const _nativePushPlugin = NativePush.instance;

Future<void> main() async {
  await _nativePushPlugin.initialize();
  runApp(const _MyApp());
}

@immutable
final class _MyApp extends StatelessWidget {
  const _MyApp();

  @override
  Widget build(final BuildContext context) =>
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native push example app'),
        ),
        body: Center(
          child: TextButton(
            onPressed: () async {
              await _nativePushPlugin.registerForRemoteNotification(
                options: [NotificationOption.alert, NotificationOption.badge, NotificationOption.sound],
                vapidKey: 'BJ4L7FepzRMspZY/utSAxySfXJVw0THgsWIGV5gausv5mvbXW103EfxQkBlXDYC+Z3nsOduWQNBlJrn6pqdQP3Y=',
              );
            },
            child: const Text('Register for notification'),
          ),
        ),
      ),
    );
}
