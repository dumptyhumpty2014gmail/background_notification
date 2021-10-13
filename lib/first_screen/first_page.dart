import 'dart:async';
import 'dart:convert';

import 'package:background_fetch/background_fetch.dart';
import '/bloc/pagebloc_bloc.dart';
import '../main.dart';
import '../second_screen/second_viewmodel.dart';
import '/second_screen/second_page.dart';
import '../notifications_my.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const String eventsKey = "fetch_events";
final DateFormat formater = DateFormat("yy.MM.dd.HH.mm.ss");
const String pre_suffixTask = 'com.dh.task1';
const String idTaskKey = 'id_task_key_dh1';
const String delayTaskKey = 'delay_task_key_dh1';

class FirstPage extends StatefulWidget {
  @override
  _FirstPageState createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  int _status = 0;
  List<String> _events = [];
  var _maxPeriod = 20; // время максимальной работы задания
  //периодичность работы в миллисекундах, вообще нужно дать выбирать пользователю в некоторых пределах и передавать в фоновое задание
  //или через наименование айдишника или через sharedpref
  var _delay = 180000;
  bool _isBackgoundPeriodicWork = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    var prefs = await SharedPreferences.getInstance();
    var json = prefs.getString(eventsKey);
    if (json != null) {
      setState(() {
        _events = jsonDecode(json).cast<String>();
      });
    }
    // Configure BackgroundFetch.
    //если конфигурирование не делать, то запускается функция, которая выполняется в фоне
    //с параметрами по умолчанию (таким образом ее можно отладить без подключения adb):
// D/TSBackgroundFetch( 7147):   "taskId": "com.dh.task_21.09.27.17.39.28",
// D/TSBackgroundFetch( 7147):   "isFetchTask": false,
// D/TSBackgroundFetch( 7147):   "minimumFetchInterval": 15,
// D/TSBackgroundFetch( 7147):   "stopOnTerminate": false,
// D/TSBackgroundFetch( 7147):   "requiredNetworkType": 0,
// D/TSBackgroundFetch( 7147):   "requiresBatteryNotLow": false,
// D/TSBackgroundFetch( 7147):   "requiresCharging": false,
// D/TSBackgroundFetch( 7147):   "requiresDeviceIdle": false,
// D/TSBackgroundFetch( 7147):   "requiresStorageNotLow": false,
// D/TSBackgroundFetch( 7147):   "startOnBoot": false,
// D/TSBackgroundFetch( 7147):   "jobService": "com.transistorsoft.flutter.backgroundfetch.HeadlessTask",
// D/TSBackgroundFetch( 7147):   "forceAlarmManager": true,
// D/TSBackgroundFetch( 7147):   "periodic": false,
// D/TSBackgroundFetch( 7147):   "delay": 180000
// D/TSBackgroundFetch( 7147): }
//если нужно установить,к примеру, startOnBoot в true, то нужно обязательно конфигурировать
    try {
      await BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: 15,
          forceAlarmManager: false,
          stopOnTerminate: false,
          startOnBoot: false,
          enableHeadless: true,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresStorageNotLow: false,
          requiresDeviceIdle: false,
          requiredNetworkType: NetworkType.NONE,
        ),
        _onBackgroundFetch,
        //_onBackgroundFetchTimeout
      );
      //print('[BackgroundFetch] результат конфигурирования: $status');
      _stopTasks();
      //зарегистрировали функцию и сразу глобальную задачу прекращаем, нужно только проверить, не прекратится ли отслеживание функции раньше, после 15 минут
      //а еще, вероятно, лучше это все делать непосредственно перед запуском задачи?
    } catch (e) {
      //print("[BackgroundFetch] configure ERROR: $e");
      setState(() {
        _status = e as int;
      });
    }
    final delayWorksTask = prefs.getInt(delayTaskKey) ?? 0;
    final taskIdString = prefs.getString(idTaskKey) ?? '';
    if (delayWorksTask != 0 && taskIdString != '') {
      //остановили выше, а теперь снова запускаем
      _delay = delayWorksTask;
      _startSheduleTaskMy(taskIdString);
      _isBackgoundPeriodicWork = true;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

//запускаем задачу. время окончания можно попытаться передавать через taskId или все таки в шаредпреференс
  void _startSheduleTaskMy(String? taskIdString) async {
    //String finishDateTime = '';
    if (taskIdString == null) {
      final finishDateTime =
          formater.format(DateTime.now().add(Duration(minutes: _maxPeriod)));
      taskIdString = "${pre_suffixTask}_$finishDateTime";
    }
    var prefs = await SharedPreferences.getInstance();
    final result = await BackgroundFetch.scheduleTask(TaskConfig(
        taskId: taskIdString,
        delay: _delay,
        periodic: false,
        forceAlarmManager: true,
        stopOnTerminate: false,
        enableHeadless: true));
    if (result) {
      prefs.setString(idTaskKey, taskIdString);
      prefs.setInt(delayTaskKey, _delay);
      setState(() {
        _isBackgoundPeriodicWork = true;
      });
    } else {
      prefs.setInt(delayTaskKey, 0);
      setState(() {
        _isBackgoundPeriodicWork = false;
      });
    }
  }

  void _onBackgroundFetch(String taskId) async {
    var prefs = await SharedPreferences.getInstance();
    var timestamp = DateTime.now();
    // This is the fetch-event callback.
    //print("[BackgroundFetch] Получено событие: $taskId");
    //print(mounted);
    if (mounted) {
      setState(() {
        _events.insert(0, "$taskId@${timestamp.toString()}");
      });
    }
    blocBackground.sendData("$taskId@${timestamp.toString()}");
    //print('Отправлено сообщение в поток');
    // Persist fetch events in SharedPreferences
    prefs.setString(eventsKey, jsonEncode(_events));

    BackgroundFetch.finish(taskId);
    if (taskId == 'flutter_background_fetch') {
      return;
    }
    final _notifications = NotificationsMy();
    final _delay = await prefs.getInt(delayTaskKey) ?? 0;
    final _delay2 = await prefs.getInt(delayTaskKey2) ?? 0;
    //print(_delay2);
    if (taskId.contains('${pre_suffixTask}_') && _delay != 0) {
      // Schedule a one-shot task when fetch event received (for testing).
      try {
        final finishString = taskId.substring(pre_suffixTask.length + 1);
        final finishDateTime = formater.parse(finishString);
        //print(finishDateTime);
        if (DateTime.now().difference(finishDateTime).inSeconds < 0) {
          BackgroundFetch.scheduleTask(TaskConfig(
              taskId: '${pre_suffixTask}_$finishString',
              delay: _delay,
              periodic: false,
              forceAlarmManager: true,
              stopOnTerminate: false,
              enableHeadless: true,
              requiresNetworkConnectivity: true,
              requiresCharging: true));
        } else {
          _notifications.initNotifications();
          _notifications.pushNotification('Отслеживание закончено', '');
          prefs.setInt(delayTaskKey, 0);
          if (mounted) {
            setState(() {
              _isBackgoundPeriodicWork = false;
            });
          }
        }
      } catch (e) {
        _notifications.initNotifications();
        _notifications.pushNotification(
            'Ошибка времени окончания', 'Обновление закончено');
        //print(e);
        prefs.setInt(delayTaskKey, 0);
        if (mounted) {
          setState(() {
            _isBackgoundPeriodicWork = false;
          });
        }
      }
    } else if (taskId.contains('${pre_suffixTask2}_') && _delay2 != 0) {
      try {
        final finishString = taskId.substring(pre_suffixTask2.length + 1);
        final finishDateTime = formater.parse(finishString);
        //print(finishDateTime);
        if (DateTime.now().difference(finishDateTime).inSeconds < 0) {
          BackgroundFetch.scheduleTask(TaskConfig(
              taskId: '${pre_suffixTask2}_$finishString',
              delay: _delay2,
              periodic: false,
              forceAlarmManager: true,
              stopOnTerminate: false,
              enableHeadless: true,
              requiresNetworkConnectivity: true,
              requiresCharging: true));
        } else {
          _notifications.initNotifications();
          _notifications.pushNotification('Отслеживание закончено 2', '');
          prefs.setInt(delayTaskKey2, 0);
          blocBackground.sendData("finish@$taskId");
        }
      } catch (e) {
        _notifications.initNotifications();
        _notifications.pushNotification(
            'Ошибка времени окончания 2', 'Обновление закончено');
        //print(e);
        prefs.setInt(delayTaskKey2, 0);
        blocBackground.sendData("finish@$taskId");
      }
    } else {
      _notifications.initNotifications();
      _notifications.pushNotification(
          'Ошибка получения времени окончания', 'Все обновления закончены');
      prefs.setInt(delayTaskKey, 0);
      prefs.setInt(delayTaskKey2, 0);
      if (mounted) {
        setState(() {
          _isBackgoundPeriodicWork = false;
        });
      }
      blocBackground.sendData("finish@$taskId");
    }
  }

  void _stopTasks() {
    BackgroundFetch.stop().then((int status) async {
      var prefs = await SharedPreferences.getInstance();
      prefs.setInt(delayTaskKey, 0);
      //print('[BackgroundFetch] stop success: $status');
      if (mounted) {
        setState(() {
          _isBackgoundPeriodicWork = false;
        });
      }
    });
  }

  void _onClickStatus() async {
    var status = await BackgroundFetch.status;
    //print('[BackgroundFetch] status: $status');
    setState(() {
      _status = status;
    });
  }

  void _onClickClear() async {
    var prefs = await SharedPreferences.getInstance();
    prefs.remove(eventsKey);
    setState(() {
      _events = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    const emptyText = Center(child: Text('События отсутствуют'));

    return Scaffold(
        appBar: AppBar(
          title: const Text('Пример работы в фоне',
              style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.amberAccent,
          //brightness: Brightness.light,
        ),
        body: Column(
          children: [
            ElevatedButton(
                onPressed: _onClickStatus, child: Text('Статус: $_status')),
            // ElevatedButton(
            //     onPressed: () {
            //       Navigator.push(context,
            //           MaterialPageRoute(builder: (_) => const SecondPage()));
            //     },
            //     child: const Text('На страницу с возвратом')),
            ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const SecondPage()));
                },
                child: const Text('На страницу без возврата')),
            ElevatedButton(
                onPressed: () {
                  context.read<PageblocBloc>().add(PageSecondEvent());
                },
                child: const Text('На вторую страницу')),

            Container(
                padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                child: Wrap(
                    //mainAxisAlignment: MainAxisAlignment.center,
                    alignment: WrapAlignment.center,
                    children: <Widget>[
                      _isBackgoundPeriodicWork
                          ? ElevatedButton(
                              onPressed: _stopTasks,
                              child: const Text('Остановить задачу'))
                          : ElevatedButton(
                              onPressed: () {
                                _startSheduleTaskMy(null);
                              },
                              child: const Text('Запустить задачу')),
                      ElevatedButton(
                          onPressed: _onClickClear,
                          child: const Text('Очистить список'))
                    ])),
            Expanded(
              child: (_events.isEmpty)
                  ? emptyText
                  : Container(
                      child: ListView.builder(
                          itemCount: _events.length,
                          itemBuilder: (BuildContext context, int index) {
                            var event = _events[index].split("@");
                            return InputDecorator(
                                decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.only(
                                        left: 5.0, top: 5.0, bottom: 5.0),
                                    labelStyle: const TextStyle(
                                        color: Colors.blue, fontSize: 20.0),
                                    labelText: "[${event[0].toString()}]"),
                                child: Text(event[1],
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 16.0)));
                          }),
                    ),
            ),
          ],
        ));
  }
}
