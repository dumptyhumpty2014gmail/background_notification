import 'package:flutter/material.dart';
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

  Future<void> pushNotification(String title, String text,
      {String? soundName}) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics;
    if (soundName == null) {
      androidPlatformChannelSpecifics = const AndroidNotificationDetails(
        myChannelId, //id channel по нему удалять
        myChannelName, //channel name
        channelDescription: 'channel from exmaple', //description
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        groupKey: 'com.android.background_notification',
        setAsGroupSummary: true,
        color: Colors.green,
      );
    } else {
      androidPlatformChannelSpecifics = AndroidNotificationDetails(
        '${myChannelId}_${soundName}', //id channel по нему удалять
        '${myChannelName}_${soundName}', //channel name
        channelDescription: 'channel from exmaple _${soundName}', //description
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound('sound${soundName}'),
        //TODO icon:
        groupKey: 'com.android.background_notification',
        setAsGroupSummary: true,
      );
    }
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin
        .show(0, title, text, platformChannelSpecifics, payload: 'item x');
  }

  Future selectNotification(String? payload) async {
    // какие-то действия...
  }
}
