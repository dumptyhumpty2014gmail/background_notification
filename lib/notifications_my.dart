import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const myChannelId = 'dumptyhumptychannelId';
const myChannelName = 'dumptyhumptychannelName';

class NotificationsMy {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    const IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings(onDidReceiveLocalNotification: null);
    const MacOSInitializationSettings initializationSettingsMacOS =
        MacOSInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
            macOS: initializationSettingsMacOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: selectNotification);
  }

  Future<void> pushNotification(String title, String text) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      myChannelId, //id channel по нему удалять
      myChannelName, //channel name
      'channel from exmaple', //description
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      enableVibration: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin
        .show(0, title, text, platformChannelSpecifics, payload: 'item x');
  }

  Future selectNotification(String? payload) async {
    // какие-то действия...
  }
}
