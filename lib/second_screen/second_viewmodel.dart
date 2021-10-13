import 'dart:async';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../notifications_my.dart';

const String eventsKey2 = "fetch_events_second";
final DateFormat formater2 = DateFormat("yy.MM.dd.HH.mm.ss");
const String pre_suffixTask2 = 'com.dh.task2';
const String idTaskKey2 = 'id_task_key_dh2';
const String delayTaskKey2 = 'delay_task_key_dh2';

void backgroundHeadlessFunction2(HeadlessTask task) async {
  final _notifications = NotificationsMy();
  _notifications.initNotifications();
  _notifications.pushNotification('Фоновая задача 2', task.taskId);
  stopTask(task.taskId);
}

void inAppBackgroundFunction2(String idTask) {
  final _notifications = NotificationsMy();
  _notifications.initNotifications();
  _notifications.pushNotification('Задача 2', idTask);
  stopTask(idTask);
}

void stopTask(String idTask) async {
  var prefs = await SharedPreferences.getInstance();
  prefs.setInt(delayTaskKey2, 0);
}

class SecondPageModel extends ChangeNotifier {
  SecondPageModel() {
    _setup();
  }
  Future<void> _setup() async {
    _history = [];
    var prefs = await SharedPreferences.getInstance();
    final int _delay = await prefs.getInt(delayTaskKey2) ?? 0;
    if (_delay > 0) {
      _isBackgroundTasks2 = true;
    }
    notifyListeners();
    blocBackground.dataStream.listen((String event) {
      //print(event);
      var eventList = event.split("@");
      if (eventList[0] == 'finish') {
        _isBackgroundTasks2 = false;
      } else {
        _history.insert(0, event);
      }
      notifyListeners();
    });
  }

  List<String> _history = [];
  List<String> get history => _history;
  bool _isBackgroundTasks2 = false;
  bool get isBackgroundTask2 => _isBackgroundTasks2;

  Future<void> setupHeadlessFunction() async {
    //bool _result =
    await BackgroundFetch.registerHeadlessTask(backgroundHeadlessFunction2);
    //print('Результат смены функции $_result');
  }

  Future<void> runTask2() async {
    //BackgroundFetch.stop();
    //если первую запустить, то эта не срабатывает
    try {
      // await BackgroundFetch.configure(
      //   BackgroundFetchConfig(
      //     minimumFetchInterval: 20,
      //     forceAlarmManager: true,
      //     stopOnTerminate: false,
      //     startOnBoot: false,
      //     enableHeadless: true,
      //     requiresBatteryNotLow: false,
      //     requiresCharging: false,
      //     requiresStorageNotLow: false,
      //     requiresDeviceIdle: false,
      //     requiredNetworkType: NetworkType.NONE,
      //   ),
      //   inAppBackgroundFunction2,
      // );
      final finishDateTime =
          formater2.format(DateTime.now().add(const Duration(minutes: 5)));
      final taskIdString = "${pre_suffixTask2}_$finishDateTime";
      startSheduleTaskMy(taskIdString);
    } catch (e) {}
  }

  void startSheduleTaskMy(String? taskIdString) async {
    //String finishDateTime = '';
    if (taskIdString == null) {
      final finishDateTime =
          formater2.format(DateTime.now().add(const Duration(minutes: 10)));
      taskIdString = "${pre_suffixTask2}_$finishDateTime";
    }
    int _delay = 30000;
    var prefs = await SharedPreferences.getInstance();
    final result = await BackgroundFetch.scheduleTask(TaskConfig(
        taskId: taskIdString,
        delay: _delay,
        periodic: false,
        forceAlarmManager: true,
        stopOnTerminate: false,
        enableHeadless: true));
    //print('запуск задачи 2 $result');
    if (result) {
      prefs.setString(idTaskKey2, taskIdString);
      prefs.setInt(delayTaskKey2, _delay);
      _isBackgroundTasks2 = true;
    } else {
      prefs.setInt(delayTaskKey2, 0);
      _isBackgroundTasks2 = false;
    }
    notifyListeners();
  }

  void stopTasks() {
    BackgroundFetch.stop().then((int status) async {
      var prefs = await SharedPreferences.getInstance();
      prefs.setInt(delayTaskKey2, 0);
      _isBackgroundTasks2 = false;
      notifyListeners();
    });
  }
}

class SecondPageProvider extends InheritedNotifier<SecondPageModel> {
  SecondPageProvider({
    Key? key,
    required this.child,
    required this.datamodel,
  }) : super(key: key, child: child, notifier: datamodel);

  final Widget child;
  final SecondPageModel datamodel;

  static SecondPageProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SecondPageProvider>();
  }
}
