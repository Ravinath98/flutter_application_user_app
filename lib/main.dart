import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/Screens/MainScreen/pages/HomePage.dart';
import 'package:flutter_app/Screens/Welcome/Welcome.dart';
import 'package:flutter_app/constants.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/models/AppUser.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:splashscreen/splashscreen.dart';

AppUser currentUserModel;
final ref = FirebaseFirestore.instance.collection('users');

const AndroidNotificationChannel channel = const AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  'This channel is used for important notifications.', // description
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('A bg message just showed up :  ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark));
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  var user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    DocumentSnapshot userRecord = await ref.doc(user.uid).get();
    if (userRecord.data() != null) {
      userRecord = await ref.doc(user.uid).get();
    }

    currentUserModel = AppUser.fromDocument(userRecord);
  }
  runApp(MyApp2(user != null ? HomePage() : WelcomeScreen()));
}

// ignore: must_be_immutable
class MyApp2 extends StatelessWidget {
  Widget _home;

  MyApp2(Widget home) {
    _home = home;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(
        gradientBackground: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: <Color>[
            appPrimaryColor2,
            appPrimaryColor,
          ],
        ),
        image: Image.asset('assets/images/AppLogoWhite.png'),
        photoSize: 70,
        loaderColor: Colors.white,
        loadingText: Text(
          "Loading ...",
          style: TextStyle(color: Colors.white),
        ),
        seconds: 3,
        title: Text(
          appName,
          style: TextStyle(
              color: Colors.white, fontSize: 50, fontFamily: 'Billabong'),
        ),
        navigateAfterSeconds: _home,
      ),
    );
  }
}
