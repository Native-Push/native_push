import 'package:flutter/material.dart';
import 'package:native_push/native_push.dart';

// Constant instance of the NativePush plugin
const _nativePushPlugin = NativePush.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the NativePush plugin
  await _nativePushPlugin.initialize(firebaseOptions: {
    "projectId": "native-push-example-84703",
    "applicationId": "1:147621026619:android:5e1626da29f9b6035fb51e",
    "apiKey": "AIzaSyCtr1BXwsYiJ6RVjMVZ9pf-4S-v7X3I__A"
  }, useDefaultNotificationChannel: true);
  _nativePushPlugin.notificationStream.listen((t) => print("Notification: $t"));

  // Run the app
  runApp(const _MyApp());
}

@immutable
// Define a stateless widget for the application
final class _MyApp extends StatelessWidget {
  // Constructor for the widget
  const _MyApp();

  @override
  Widget build(final BuildContext context) =>
      // Define the MaterialApp
      MaterialApp(
        home: Scaffold(
          // Define the AppBar
          appBar: AppBar(
            title: const Text('Native push example app'),
          ),
          // Define the body of the Scaffold
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  // On button press, register for remote notifications
                  onPressed: () async {
                    await _nativePushPlugin.registerForRemoteNotification(
                      options: [
                        .alert,
                        .badge,
                        .sound
                      ],
                      vapidKey:
                          'BJ4L7FepzRMspZY/utSAxySfXJVw0THgsWIGV5gausv5mvbXW103EfxQkBlXDYC+Z3nsOduWQNBlJrn6pqdQP3Y=',
                    );
                  },
                  child: const Text('Register for notification'),
                ),
                TextButton(
                  // On button press, print notification
                  onPressed: () async {
                    print(
                      await _nativePushPlugin.notificationToken,
                    );
                  },
                  child: const Text('Print token'),
                ),
              ],
            ),
          ),
        ),
      );
}
