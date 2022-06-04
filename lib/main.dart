import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reminder_app/pages/authorized_user.dart';
import 'package:reminder_app/service/auth.dart';
import 'package:reminder_app/service/jop.dart';
import 'package:reminder_app/service/notification.dart';
import 'package:reminder_app/service/person.dart';

import 'builders.dart';
import 'constants.dart';
import 'model/person.dart' as models;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: options);
  NotificationService().configureLocalTimeZone();
  runApp(MaterialApp(
    home: const ReminderApp(),
    debugShowCheckedModeBanner: false,
    theme: mainTheme,
  ));

  await flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: NotificationService().onSelectNotification);
}

class ReminderApp extends StatefulWidget {
  const ReminderApp({Key? key}) : super(key: key);

  @override
  _ReminderAppState createState() => _ReminderAppState();
}

class _ReminderAppState extends State<ReminderApp> {
  final AuthService _authService = AuthService();
  final PersonService _personService = PersonService();

  String _name = "";
  String _email = "";
  String _password = "";
  String _confirmPassword = "";
  bool _visible = true;
  bool _hasAccount = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: mainTheme.backgroundColor,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0, top: 40),
                child: Text("WELCOME",
                    style: GoogleFonts.getFont("Dancing Script",
                        fontWeight: FontWeight.bold, fontSize: 50, letterSpacing: 15, color: mainTheme.primaryColor)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 40.0, bottom: 20),
                child: Center(
                  child: Text("Reminder\nAssistant\nApp",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.getFont(
                        "Dancing Script",
                        fontWeight: FontWeight.bold,
                        fontSize: 40,
                        letterSpacing: 10,
                        color: mainTheme.primaryColor,
                      )),
                ),
              ),
              !_hasAccount
                  ? CustomCard(
                      padding: const EdgeInsets.all(8.0),
                      backGroundColor: mainTheme.backgroundColor,
                      borderRadius: 10.0,
                      horizontalMargin: 20.0,
                      verticalMargin: 10.0,
                      child: CustomTextField(
                        hintText: "Name",
                        fontSize: 20,
                        textColor: Colors.black,
                        onChanged: (value) {
                          _name = value;
                        },
                        prefixIcon: Icon(Icons.person, color: mainTheme.primaryColor),
                      ),
                    )
                  : const SizedBox(),
              Padding(
                padding: _hasAccount ? const EdgeInsets.only(top: 30.0) : const EdgeInsets.all(0.0),
                child: CustomCard(
                  padding: const EdgeInsets.all(8.0),
                  backGroundColor: mainTheme.backgroundColor,
                  borderRadius: 10.0,
                  horizontalMargin: 20.0,
                  verticalMargin: 10.0,
                  child: CustomTextField(
                    hintText: "E-Mail",
                    fontSize: 20,
                    textColor: Colors.black,
                    onChanged: (value) {
                      _email = value;
                    },
                    prefixIcon: const Icon(Icons.email, color: Colors.lightBlue),
                  ),
                ),
              ),
              CustomCard(
                padding: const EdgeInsets.all(8.0),
                backGroundColor: mainTheme.backgroundColor,
                borderRadius: 10.0,
                horizontalMargin: 20.0,
                verticalMargin: 10.0,
                child: CustomTextField(
                  hintText: "Password",
                  fontSize: 20,
                  textColor: Colors.black,
                  isObscureText: !_visible,
                  onChanged: (value) {
                    _password = value;
                  },
                  prefixIcon: const Icon(Icons.security, color: Colors.red),
                  suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _visible = !_visible;
                        });
                      },
                      icon: _visible
                          ? Icon(
                              Icons.visibility,
                              color: mainTheme.primaryColor,
                            )
                          : Icon(Icons.visibility_off, color: mainTheme.primaryColor)),
                ),
              ),
              !_hasAccount
                  ? CustomCard(
                      padding: const EdgeInsets.all(8.0),
                      backGroundColor: mainTheme.backgroundColor,
                      borderRadius: 10.0,
                      horizontalMargin: 20.0,
                      verticalMargin: 10.0,
                      child: CustomTextField(
                        hintText: "Re-Password",
                        fontSize: 20,
                        textColor: Colors.black,
                        isObscureText: !_visible,
                        onChanged: (value) {
                          _confirmPassword = value;
                        },
                        prefixIcon: const Icon(Icons.security, color: Colors.red),
                      ),
                    )
                  : const SizedBox(),
              CustomCard(
                backGroundColor: Colors.deepPurple,
                borderRadius: 20.0,
                padding: const EdgeInsets.all(8.0),
                verticalMargin: 25.0,
                horizontalMargin: 120.0,
                child: CustomTextButton(
                  text: _hasAccount ? "Login" : " Sign Up",
                  textStyle: const TextStyle(color: Colors.white, fontSize: 25),
                  onPressed: () async {
                    bool _authSuccess = true;

                    if (_hasAccount) {
                      await _authService.signIn(_email, _password).catchError((e) {
                        Fluttertoast.showToast(msg: e.toString().split("]")[1], webShowClose: true, webPosition: "center", timeInSecForIosWeb: 3);
                        _authSuccess = false;
                      });
                    }

                    if (_name.isEmpty && !_hasAccount) {
                      Fluttertoast.showToast(msg: "Field 'name' can not be empty!", webShowClose: true, webPosition: "center", timeInSecForIosWeb: 3);
                    }

                    if (_password.compareTo(_confirmPassword) != 0 && !_hasAccount) {
                      Fluttertoast.showToast(msg: "Passwords are not the same", webShowClose: true, webPosition: "center", timeInSecForIosWeb: 3);
                    }

                    if (!_hasAccount) {
                      await _personService.createPerson(models.Person(name: _name, email: _email), _password).catchError((e) {
                        Fluttertoast.showToast(msg: e.toString().split("]")[1], webShowClose: true, webPosition: "center", timeInSecForIosWeb: 3);
                        _authSuccess = false;
                      });
                    }

                    if (_authSuccess) {
                      switchPage(context,
                          AuthorizedPersonPage(person: models.Person(id: FirebaseAuth.instance.currentUser!.uid, name: _name, email: _email)));
                    }
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _hasAccount ? "Does Not Have Account ?" : "Have An Account ? ",
                    style: const TextStyle(fontSize: 15, color: Colors.black),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 0),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _hasAccount = !_hasAccount;
                        });
                      },
                      child: Text(
                        _hasAccount ? "Sign Up" : "Login",
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.deepPurple),
                      ),
                    ),
                  )
                ],
              ),
              CustomCard(
                padding: const EdgeInsets.all(8.0),
                backGroundColor: mainTheme.backgroundColor,
                borderRadius: 10.0,
                horizontalMargin: 100.0,
                verticalMargin: 10.0,
                child: CustomTextButton(
                  text: "TEST",
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.deepPurple),
                  onPressed: () {
                    _authService.signIn("yusufaktok@gmail.com", "yusuf123").then((value) => switchPage(
                        context,
                        AuthorizedPersonPage(
                            person: models.Person(id: FirebaseAuth.instance.currentUser!.uid, name: "Yusuf Aktoğ", email: "yusufaktok@gmail.com"))));
                  },
                ),
              ),
              TextButton(
                  onPressed: () {
                    openUrl('https://flutter.dev');
                  },
                  child: Text("OPEN URL")),
              TextButton(
                  onPressed: () {
                    makePhoneCall("+90 5541849047");
                  },
                  child: Text("PHONE CALL")),
              TextButton(
                  onPressed: () {
                    sendEmail("haloaktog@gmail.com", "Test", "Sent From flutter mobile app");
                  },
                  child: Text("SEND email")),
              TextButton(
                  onPressed: () {
                    sendSms("+90 5541849047", "Sent From flutter mobile app");
                  },
                  child: Text("SEND sms"))
            ]),
          ),
        ),
      ),
    );
  }
}
