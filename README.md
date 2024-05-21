# Native Push Plugin

The Native Push Plugin is a Flutter plugin that provides seamless integration of push notifications across different platforms including Android, iOS, macOS, and Web. This plugin allows your Flutter application to receive and handle remote notifications with ease.

## Features

- Supports Firebase Cloud Messaging (FCM) for Android.
- Supports Apple Push Notification Service (APNs) for iOS and macOS.
- Supports Web Push for web applications.
- Handles push notifications while the app is in the foreground, background, or terminated.
- Provides methods to initialize the plugin, register for remote notifications, and retrieve the notification token.
- Supports various notification options like alert, badge, sound, and more.

## Installation

Add the following dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  native_push: ^1.0.0
```

Then run `flutter pub get` to install the plugin.

## Usage

### Import the Plugin

```dart
import 'package:native_push/native_push.dart';
```

### Initialize the Plugin

Before using the plugin, you need to initialize it. This is typically done in the `main.dart` file of your Flutter project.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the native push plugin
  await NativePush.instance.initialize(
    firebaseOptions: {
      'apiKey': 'YOUR_API_KEY',
      'projectId': 'YOUR_PROJECT_ID',
      'messagingSenderId': 'YOUR_MESSAGING_SENDER_ID',
      'appId': 'YOUR_APP_ID',
    },
    useDefaultNotificationChannel: true,
  );

  runApp(MyApp());
}
```

The firebaseOptions can be omitted when not using fcm. You can use
the `extract_fcm_options` script provided in the repository to
extract the information from the `google-services.json`.

```bash
cat google-services.json | ./extract_fcm_options.sh <android-bundle-id>
```

### Register for Remote Notifications

You need to register for remote notifications to get a notification token.

```dart
await NativePush.instance.registerForRemoteNotification(
  options: [NotificationOption.alert, NotificationOption.sound],
  vapidKey: 'YOUR_VAPID_KEY', // For web push, can be omitted otherwise
);
```

### Handling Incoming Notifications

You can listen for incoming notifications using the `notificationStream`.

```dart
NativePush.instance.notificationStream.listen((notification) {
  // Handle the notification
  print('Received notification: $notification');
});
```

### Get Initial Notification

To handle the notification that opened the app, you can use `initialNotification`.

```dart
final initialNotification = await NativePush.instance.initialNotification();
if (initialNotification != null) {
  // Handle the initial notification
  print('Initial notification: $initialNotification');
}
```

### Retrieve the Notification Token

You can retrieve the current notification token with the following method:

```dart
final (service, token) = await NativePush.instance.notificationToken;
print('Notification Service: $service, Token: $token');
```

## Platform Specifics

### Android

For Android, ensure that you have add the following metadata to your application.

```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="native_push_notification_channel" />
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@android:drawable/ic_input_add" />
```

You can only use `native_push_notification_channel` if you set
`useDefaultNotificationChannel` in initialize to true. Otherwise you have
to create and specify your own notification channel.

You also need to the following to your main activity intent filter:

```xml
<action android:name="com.opdehipt.native_push.PUSH"/>
```

### iOS

You have to add the `Push Notification` Capability.

If you want to support images in your notification, you also have to add
the `Background Modes` Capability and check `Remote Notifications`.
You also have to add `Notification Service Extension` to your app and
replace the code with the following:
```swift
import NativePushNotificationService

final class NotificationService: NativePushNotificationService {}
```
The `NativePushNotificationService` can be imported via the
`Swift Package Manager` from
[here](https://github.com/Native-Push/native_push_notification_service).

### MacOS

You only have to add the `Push Notification` Capability.

### Web

Please add the
[native_push.min.js](https://github.com/Native-Push/native_push/blob/main/example/web/native_push.min.js)
to your web folder and it to
`native_push.js`. You should also add one of
[native_push_sw.min.js](https://github.com/Native-Push/native_push/blob/main/example/web/native_push_sw.min.js) or
[native_push_sw_non_localize.min.js](https://github.com/Native-Push/native_push/blob/main/example/web/native_push_sw_non_localize.min.js)
to your web folder and rename it to `native_push_sw.js`. The normal
script should be used if you want to localize the notification on the
client side. Otherwise you should add the non_localize script. If you
add the localize script, you also have to add the
[localization.js](https://github.com/Native-Push/native_push/blob/main/example/web/localization.js)
and add your localization logic to the `localization` function.
You don't have to import any of the javascript files in your `index.html`.

## Example

An example Flutter app demonstrating the usage of the Native Push Plugin can be found in the `example` directory.

## Contributing

Contributions are welcome! Please submit a pull request or create an issue if you find a bug or have a feature request.

## License

This project is licensed under the BSD-3 License. See the
[LICENSE](LICENSE) file for details.