import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:reminder_app/model/person.dart' as models;
import 'package:rxdart/rxdart.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../constants.dart';
import '../model/notification.dart';
import '../pages/detailed_task_page.dart';
import 'jop.dart';

class NotificationService {
  String? selectedNotificationPayload;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final BehaviorSubject<ReceivedNotification> didReceiveLocalNotificationSubject = BehaviorSubject<ReceivedNotification>();
  final BehaviorSubject<String?> selectNotificationSubject = BehaviorSubject<String?>();

  Future<void> configureLocalTimeZone() async {
    if (kIsWeb) {
      return;
    }
    tz.initializeTimeZones();
    final String? timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName!));
  }

  void configureSelectNotificationSubject(context, models.Person person) {
    selectNotificationSubject.stream.listen((String? payload) async {
      debugPrint("reached");

      /*FirebaseFirestore.instance.collection("People").doc(person.id).collection("Tasks").doc(payload).snapshots().forEach((element) {
        phoneNumber = element.data()!["phoneNumber"];
        emailAddress = element.data()!["emailAddress"];
        url = element.data()!["url"];
        subject = element.data()!["subject"];
        body = element.data()!["body"];
        jop = element.data()!["jop"];
      });
      debugPrint(jop);
      switch (jop) {
        case "none":
          await switchPage(context, AuthorizedPersonPage(person: person));
          break;
        case "phone call":
          await makePhoneCall(phoneNumber);
          break;
        case "send email":
          await sendEmail(emailAddress, subject, body);
          break;
        case "open url":
          await openUrl(url);
          break;
        case "send sms":
          await sendSms(phoneNumber, body);
          break;
      }*/
    });
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelNotificationById(int notificationId) async {
    await flutterLocalNotificationsPlugin.cancel(notificationId);
  }

  void configureDidReceiveLocalNotificationSubject(context) {
    didReceiveLocalNotificationSubject.stream.listen((ReceivedNotification receivedNotification) async {
      await showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: receivedNotification.title != null ? Text(receivedNotification.title!) : null,
          content: receivedNotification.body != null ? Text(receivedNotification.body!) : null,
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                Navigator.of(context, rootNavigator: true).pop();
                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => DetailedTaskPage(),
                  ),
                );
              },
              child: const Text('Ok'),
            )
          ],
        ),
      );
    });
  }

  Future<void> createScheduledNotificationWithRepeatInterval(
      String title, String body, int notificationId, RepeatInterval repeatInterval, String taskId) async {
    await flutterLocalNotificationsPlugin.periodicallyShow(notificationId, title, body, repeatInterval, platformChannelSpecifics,
        payload: taskId, androidAllowWhileIdle: true);
  }

  Future<void> createScheduledNotificationWithNoRepetition(String title, String body, int notificationId, DateTime dateTime, String taskId) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(notificationId, title, body, createScheduledDate(dateTime), platformChannelSpecifics,
        payload: taskId, androidAllowWhileIdle: true, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
  }

  Future<void> createCustomScheduledNotification(
      String title, String body, int notificationId, DateTime dateTime, RepetitionType repetitionType, String taskId) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(notificationId, title, body, createScheduledDate(dateTime), platformChannelSpecifics,
        payload: taskId,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: convertToDateTimeComponents(repetitionType));
  }

  tz.TZDateTime createScheduledDate(DateTime dateTime) {
    tz.TZDateTime scheduledDate = tz.TZDateTime.from(dateTime, tz.getLocation("Europe/Istanbul"));
    return scheduledDate;
  }

  DateTimeComponents convertToDateTimeComponents(RepetitionType repetitionType) {
    switch (repetitionType) {
      case RepetitionType.daily:
        return DateTimeComponents.time;
      case RepetitionType.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case RepetitionType.monthly:
        return DateTimeComponents.dayOfMonthAndTime;
      case RepetitionType.yearly:
        return DateTimeComponents.dateAndTime;
    }
  }

  Future onSelectNotification(String? payload) async {
    String phoneNumber = "";
    String emailAddress = "";
    String url = "";
    String subject = "";
    String body = "";
    String jop = "none";

    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection('People')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("Tasks")
        .doc(payload)
        .snapshots()
        .firstWhere((element) => element.id == payload);

    if (!documentSnapshot.exists) {
      return;
    }
    jop = documentSnapshot["jop"];

    switch (jop) {
      case "open url":
        url = documentSnapshot["url"];
        await openUrl(url);
        break;

      case "phone call":
        phoneNumber = documentSnapshot["phoneNumber"];
        await makePhoneCall(phoneNumber);
        break;

      case "send email":
        emailAddress = documentSnapshot["emailAddress"];
        subject = documentSnapshot["subject"];
        body = documentSnapshot["body"];
        await sendEmail(emailAddress, subject, body);
        break;

      case "send sms":
        phoneNumber = documentSnapshot["phoneNumber"];
        body = documentSnapshot["body"];
        await sendSms(phoneNumber, body);
        break;

      case "none":
      default:
        break;
    }

    /* StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ,
      builder: (_, snapshot) {
        try {
          final docs = snapshot.data!.docs;
          for (var element in docs) {
            if (element.id == docId) {
              print('bingo');
              phoneNumber = element.data().keys.contains("phoneNumber") ? element.data()["phoneNumber"] : "";
              emailAddress = element.data().keys.contains("emailAddress") ? element.data()["emailAddress"] : "";
              url = element.data().keys.contains("url") ? element.data()["url"] : "";
              subject = element.data().keys.contains("subject") ? element.data()["subject"] : "";
              body = element.data().keys.contains("body") ? element.data()["body"] : "";
              jop = element.data().keys.contains("jop") ? element.data()["jop"] : "";
            }
          }
        } on Error {}
        return const Text("");
      },
    );*/
  }
}
