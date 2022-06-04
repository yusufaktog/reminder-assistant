import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:reminder_app/service/notification.dart';
import 'package:reminder_app/service/task.dart';

import '../builders.dart';
import '../constants.dart';
import '../model/task.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: options);

  runApp(MaterialApp(
    home: const CreateTaskPage(),
    debugShowCheckedModeBanner: false,
    theme: mainTheme,
  ));
}

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({Key? key}) : super(key: key);

  @override
  _CreateTaskPageState createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final List<String> _priorityItems = <String>['Minor', 'Medium', 'Major', 'Critical'];
  final List<String> _repetitionItems = <String>["No Repetition", "Every Minute", "Hourly", "Daily", "Weekly", "Monthly", "Yearly"];

  var _title = "";
  var _description = "";
  var _priority = "";
  var _repetition = "No Repetition";
  var _time = DateTime.now();
  var _initialTimeText = "Open Time Picker";
  var _timeButtonDisabled = false;

  final Set<String> _errors = {};
  final TaskService _taskService = TaskService();
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: mainTheme.backgroundColor,
        appBar: AppBar(backgroundColor: mainTheme.primaryColor, centerTitle: true, title: const Text("Create Task")),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: CustomUnderlinedTextField(
                    style: mainTheme.textTheme.headline5!,
                    onChanged: (value) {
                      _title = value;
                    },
                    labelText: "Title",
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: CustomUnderlinedTextField(
                    style: mainTheme.textTheme.headline5!,
                    onChanged: (value) {
                      _description = value;
                    },
                    labelText: "Description",
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Priority",
                    style: mainTheme.textTheme.headline5,
                  ),
                  const SizedBox(width: 120),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: CustomDropDownMenu(
                      onChanged: (value) {
                        _priority = value;
                        setState(() {
                          _priorityItems.remove(value);
                          _priorityItems.insert(0, value);
                        });
                      },
                      items: _priorityItems,
                      dropDownValue: _priorityItems.first,
                      itemTextStyle: mainTheme.textTheme.headline5,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Repetition", style: mainTheme.textTheme.headline5),
                  const SizedBox(width: 40),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: CustomDropDownMenu(
                      onChanged: (dynamic value) async {
                        _repetition = value;
                        setState(() {
                          _repetitionItems.remove(value);
                          _repetitionItems.insert(0, value);
                          if (_repetition == "No Repetition" || _repetition == "Every Minute" || _repetition == "Hourly") {
                            _timeButtonDisabled = true;
                          } else {
                            _timeButtonDisabled = false;
                          }
                        });
                      },
                      dropDownValue: _repetitionItems.first,
                      items: _repetitionItems,
                      dropDownColor: Colors.white,
                      itemTextStyle: mainTheme.textTheme.headline5,
                      onTap: (value) {
                        _repetition = value;
                      },
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Time", style: mainTheme.textTheme.headline5),
                  const SizedBox(width: 70),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: CustomTextButton(
                        text: _timeButtonDisabled ? DateTime.now().toString().split('.')[0] : _initialTimeText,
                        textStyle: mainTheme.textTheme.headline5,
                        onPressed: () {
                          if (_timeButtonDisabled) {
                            return;
                          }

                          DatePicker.showDateTimePicker(context,
                              currentTime: DateTime.now().add(const Duration(minutes: 1)),
                              maxTime: DateTime.now().add(const Duration(days: 365)),
                              minTime: DateTime.now().add(const Duration(minutes: 1)), onCancel: () {
                            setState(() {
                              _initialTimeText = "Open Time Picker";
                            });
                          }, onChanged: (DateTime? time) {
                            _time = time!;

                            setState(() {
                              _initialTimeText = _time.toString().split('.')[0];
                            });
                          }, onConfirm: (DateTime? time) {
                            _time = time!;

                            setState(() {
                              _initialTimeText = _time.toString().split('.')[0];
                            });
                          }, showTitleActions: true, theme: datePickerTheme);
                        }),
                  ),
                ],
              ),
              CustomCard(
                  backGroundColor: mainTheme.primaryColor,
                  verticalMargin: 30,
                  horizontalMargin: 130,
                  padding: const EdgeInsets.all(4.0),
                  child: CustomTextButton(
                    onPressed: () async {
                      if (_description.isEmpty) {
                        _errors.add(descriptionError);
                      }
                      if (_title.isEmpty) {
                        _errors.add(titleError);
                      }
                      if (_initialTimeText == "Open Time Picker") {
                        _errors.add(timeError);
                      }

                      int _notificationId = (createRandomNotificationId() / 1000).toInt();
                      // fit to 2^32
                      while (_notificationId >= 0x7fffffff) {
                        _notificationId = (_notificationId * Random().nextDouble()).toInt();
                        debugPrint(_notificationId.toString());
                      }

                      if (_errors.isNotEmpty) {
                        for (var error in _errors) {
                          showToastMessage(error, Colors.black, 20);
                        }
                        return;
                      }

                      String _taskId = await _taskService.createTask(Task(
                          priority: _priority,
                          description: _description,
                          notificationId: _notificationId,
                          time: _time.toString().split('.')[0],
                          title: _title,
                          repetition: _repetition));
                      debugPrint("task id sent: " + _taskId);

                      await _taskService.getDocRef(_taskId).update({'jop': "open url", 'url': 'https://www.google.com'});

                      if (_repetition == "No Repetition") {
                        _notificationService.createScheduledNotificationWithNoRepetition(_title, _description, _notificationId, _time, _taskId);
                      } else if (_repetition == "Every Minute") {
                        _notificationService.createScheduledNotificationWithRepeatInterval(
                            _title, _description, _notificationId, RepeatInterval.everyMinute, _taskId);
                      } else if (_repetition == "Hourly") {
                        _notificationService.createScheduledNotificationWithRepeatInterval(
                            _title, _description, _notificationId, RepeatInterval.hourly, _taskId);
                      } else {
                        _notificationService.createCustomScheduledNotification(
                            _title, _description, _notificationId, _time, convertStringToRepetitionType(_repetition), _taskId);
                      }

                      showToastMessage("Task successfully created", Colors.black, 20);
                      Navigator.of(context).pop();
                      _errors.clear();
                    },
                    textStyle: mainTheme.textTheme.headline2,
                    text: "CREATE",
                  ),
                  borderRadius: 20),
            ],
          ),
        ),
      ),
    );
  }
}
