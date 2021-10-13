import 'dart:async';
import 'dart:convert';

import 'package:background_fetch/background_fetch.dart';
import 'package:background_fetch_example/bloc/pagebloc_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'first_screen/first_page.dart';
import 'notifications_my.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'second_screen/second_page.dart';
import 'second_screen/second_viewmodel.dart';

// DateTime? getFinishDateTimeFromIdTask(idTask) {
//   if (idTask.contains(pre_suffixTask)) {
//     try {
//       final finishString = idTask.substring(pre_suffixTask.length + 1);
//       return formater.parse(finishString);
//     } catch (e) {}
//   }
//   return null;
// }
class BlocBackgroundTasks {
  static final BlocBackgroundTasks _blockBackgroundTasks =
      BlocBackgroundTasks._internal();
  factory BlocBackgroundTasks() {
    return _blockBackgroundTasks;
  }
  BlocBackgroundTasks._internal();
  final _dataController = StreamController<String>.broadcast();
  get sendData => (value) async {
        _dataController.sink.add(value);
      };
  get dataStream => _dataController.stream;
  void dispose() {
    _dataController.close();
  }
}

final blocBackground = BlocBackgroundTasks();

/// Эта функция выполняется, когда приложение выгружено
/// получает объект task с двумя параметрами taskId и timeout
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  final taskId = task.taskId;
  final timeout = task.timeout;

  final timestamp = DateTime.now();

  var prefs = await SharedPreferences.getInstance();

  // Read fetch_events from SharedPreferences
  var events = <String>[];
  var json = prefs.getString(eventsKey);
  if (json != null) {
    events = jsonDecode(json).cast<String>();
  }
  // Записываем события
  events.insert(0, "$taskId@$timestamp [в фоне]");
  //  blocBackground.sendData("$taskId@${timestamp.toString()}");
  prefs.setString(eventsKey, jsonEncode(events));
  if (timeout) {
    //print("[BackgroundFetch] Headless task timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }
  //print('Фоновая задача');
  blocBackground.sendData("$taskId@${timestamp.toString()}"); //не отрабатывает
  //print('Событие отправлено');
  BackgroundFetch.finish(taskId);
  if (taskId == 'flutter_background_fetch') {
    return;
  }
  final _notifications = NotificationsMy();
  //TOD считываем период, если ошибка, сообщаем, иначе запускаем
  final _delay = await prefs.getInt(delayTaskKey) ?? 0;
  final _delay2 = await prefs.getInt(delayTaskKey2) ?? 0;
  //print(_delay2);
  //print(taskId.contains(pre_suffixTask2));
  if (taskId.contains('${pre_suffixTask}_') && _delay > 0) {
    try {
      final finishString = taskId.substring(pre_suffixTask.length + 1);
      final finishDateTime = formater.parse(finishString);
      if (DateTime.now().difference(finishDateTime).inSeconds < 0) {
        BackgroundFetch.scheduleTask(TaskConfig(
            taskId: "${pre_suffixTask}_$finishString",
            delay: _delay,
            periodic: false,
            forceAlarmManager: true,
            stopOnTerminate: false,
            enableHeadless: true,
            requiresNetworkConnectivity: true,
            requiresCharging: true));
      } else {
        _notifications.initNotifications();
        _notifications.pushNotification(
            'Фоновое обновление закончено', 'Можно запустить снова');
        prefs.setInt(delayTaskKey, 0);
      }
    } catch (e) {
      _notifications.initNotifications();
      _notifications.pushNotification(
          'Ошибка определения времени окончания', 'Обновление закончено');
      prefs.setInt(delayTaskKey, 0);
    }
  } else if (taskId.contains('${pre_suffixTask2}_') && _delay2 != 0) {
    try {
      final finishString = taskId.substring(pre_suffixTask2.length + 1);
      final finishDateTime = formater.parse(finishString);
      if (DateTime.now().difference(finishDateTime).inSeconds < 0) {
        BackgroundFetch.scheduleTask(TaskConfig(
            taskId: "${pre_suffixTask2}_$finishString",
            delay: _delay2,
            periodic: false,
            forceAlarmManager: true,
            stopOnTerminate: false,
            enableHeadless: true,
            requiresNetworkConnectivity: true,
            requiresCharging: true));
      } else {
        _notifications.initNotifications();
        _notifications.pushNotification(
            'Фоновое обновление закончено 2', 'Можно запустить снова');
        prefs.setInt(delayTaskKey2, 0);
      }
    } catch (e) {
      _notifications.initNotifications();
      _notifications.pushNotification(
          'Ошибка определения времени окончания 2', 'Обновление закончено');
      prefs.setInt(delayTaskKey2, 0);
    }
  } else {
    _notifications.initNotifications();
    _notifications.pushNotification(
        'Ошибка определения времени окончания или периода',
        'Обновление закончено');
    prefs.setInt(delayTaskKey, 0);
    prefs.setInt(delayTaskKey2, 0);
  }
}

Future<void> main() async {
  runApp(BlocProvider(
    create: (context) => PageblocBloc(),
    child: const MyApp(),
  ));

  //Регистрируем функцию, которая работает в фоне, когда приложение выгружено
  await BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
  //print('Результат регистрации $registryResult');
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Эксперименты',
      home: BlocBuilder<PageblocBloc, PageblocState>(
        builder: (context, state) {
          // if (state is PageFirstState) {
          //   return ErrorOutput(message: state.message);
          // }
          if (state is PageFirstState) {
            return FirstPage();
          }
          if (state is PageSecondState) {
            return const SecondPage();
          }
          return FirstPage();
        },
      ),
    );
  }
}
