import '/first_screen/first_page.dart';
import 'second_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/bloc/pagebloc_bloc.dart';

class SecondPage extends StatefulWidget {
  const SecondPage({Key? key}) : super(key: key);

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  final SecondPageModel _model = SecondPageModel();
  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Проверка смены страницы',
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.amberAccent,
      ),
      body: SecondPageProvider(
        datamodel: _model,
        child: Center(
          child: Column(
            children: [
              const ChangeBackgroundFunctionWIdget(),
              const StartStopTask2Widget(),
              ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => FirstPage()));
                  },
                  child: const Text('Назад')),
              ElevatedButton(
                  onPressed: () {
                    context.read<PageblocBloc>().add(PageFirstEvent());
                  },
                  child: const Text('На первую страницу')),
              const EventsListWidget()
            ],
          ),
        ),
      ),
    );
  }
}

class StartStopTask2Widget extends StatelessWidget {
  const StartStopTask2Widget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final datamodel = SecondPageProvider.of(context)?.datamodel;
    if (datamodel == null) {
      return const Text('Функционал запуска задачи 2');
    }
    if (datamodel.isBackgroundTask2) {
      return ElevatedButton(
          onPressed: () {
            datamodel.stopTasks();
          },
          child: const Text('Остановить вторую подзадачу'));
    } else {
      return ElevatedButton(
          onPressed: () {
            datamodel.runTask2();
          },
          child: const Text('Запустить вторую подзадачу'));
    }
  }
}

class ChangeBackgroundFunctionWIdget extends StatelessWidget {
  const ChangeBackgroundFunctionWIdget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final datamodel = SecondPageProvider.of(context)?.datamodel;
    return ElevatedButton(
        onPressed: () {
          if (datamodel != null) {
            datamodel.setupHeadlessFunction();
          }
        },
        child: const Text('Переопредлить функцию в фоне'));
  }
}

class EventsListWidget extends StatelessWidget {
  const EventsListWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final datamodel = SecondPageProvider.of(context)?.datamodel;
    if (datamodel == null) {
      return const Text('Список событий пустой');
    } else {
      final history = datamodel.history;
      return Expanded(
          child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (BuildContext contex, int index) {
                var event = history[index].split("@");
                return InputDecorator(
                    decoration: InputDecoration(
                        contentPadding: const EdgeInsets.only(
                            left: 5.0, top: 5.0, bottom: 5.0),
                        labelStyle:
                            const TextStyle(color: Colors.blue, fontSize: 20.0),
                        labelText: "[${event[0].toString()}]"),
                    child: Text(event[1],
                        style: const TextStyle(
                            color: Colors.black, fontSize: 16.0)));
              }));
    }
  }
}
