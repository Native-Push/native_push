enum NotificationOption {
  alert(name: 'alert'),
  badge(name: 'badge'),
  sound(name: 'sound'),
  carPlay(name: 'carPlay'),
  criticalAlert(name: 'criticalAlert'),
  providesAppNotificationSettings(name: 'providesAppNotificationSettings'),
  provisional(name: 'provisional');

  const NotificationOption({required this.name});

  final String name;
}
