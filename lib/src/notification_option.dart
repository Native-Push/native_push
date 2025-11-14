/// Enum representing different options for notifications.
enum NotificationOption {
  /// Option for displaying an alert.
  alert(name: 'alert'),

  /// Option for displaying a badge on the app icon.
  badge(name: 'badge'),

  /// Option for playing a sound with the notification.
  sound(name: 'sound'),

  /// Option for showing notifications on CarPlay.
  carPlay(name: 'carPlay'),

  /// Option for showing critical alerts.
  criticalAlert(name: 'criticalAlert'),

  /// Option for providing app-specific notification settings.
  providesAppNotificationSettings(name: 'providesAppNotificationSettings'),

  /// Option for provisional notifications that do not require explicit permission.
  provisional(name: 'provisional');

  /// Constructor to create a notification option with a specific name.
  const NotificationOption({required this.name});

  /// The name of the notification option.
  final String name;
}
