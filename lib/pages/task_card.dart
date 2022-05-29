import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:reminder_app/service/notification.dart';

import '../model/task.dart';

class TaskCard extends StatefulWidget {
  final Task task;

  const TaskCard({Key? key, required this.task}) : super(key: key);

  @override
  _TaskCardState createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: adjustCardPriorityColor(widget.task.priority),
      child: SizedBox(
        height: 150,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                children: [
                  Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(widget.task.title),
                      )),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        widget.task.time,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),
            Text(
              widget.task.description,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
            TextButton(
              child: const Text("Cancel Notification"),
              onPressed: () {
                _notificationService.cancelNotificationById(widget.task.notificationId);
              },
            )
          ],
        ),
      ),
    );
  }

  Color adjustCardPriorityColor(String priority) {
    switch (priority) {
      case "Minor":
        return Colors.grey;
      case "Medium":
        return Colors.lightGreen;
      case "Major":
        return Colors.yellow;
      case "Critical":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String adjustDigitPrecision(int digit) {
    String digitStr = digit.toString();

    switch (digitStr.length) {
      case 1:
        return "0" + digitStr;
      default:
        return digitStr;
    }
  }
}
