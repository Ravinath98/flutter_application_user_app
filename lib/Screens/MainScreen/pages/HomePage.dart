import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/Screens/MainScreen/pages/NotificationsPage.dart';
import 'package:flutter_app/Screens/MainScreen/pages/ProfilePage.dart';
import 'package:flutter_app/Screens/MainScreen/pages/SearchPage.dart';
import 'package:flutter_app/Screens/MainScreen/pages/TimelinePage.dart';
import 'package:flutter_app/Screens/MainScreen/pages/MessengerPage.dart';
import 'package:flutter_app/constants.dart';
import 'package:flutter_app/google_map.dart';
import 'package:flutter_app/main.dart';
//import 'package:flutter_app/temp.dart';
import 'package:flutter_app/user_tracker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
//import 'package:provider/provider.dart';
//import 'package:flutter_app/location_latitude.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../chat.dart';
//import '../../../usersMap.dart';

class NavigationItem {
  const NavigationItem(this.title, this.icon);
  final String title;
  final IconData icon;
}

const List<NavigationItem> allNavigationItems = <NavigationItem>[
  NavigationItem('Home', Icons.home),
  NavigationItem('Search', Icons.search),
  NavigationItem('Message', Icons.chat_bubble),
  NavigationItem('Notification', Icons.notifications),
  NavigationItem('Profile', Icons.person),
  NavigationItem('Bot', Icons.adb_rounded),
  NavigationItem('Map', Icons.map_rounded),
];

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  //iiiiiiiiiiiippppppppppppppppppppppppppppppppppppp below
  /*
  String currentUserId = FirebaseAuth.instance.currentUser.uid;

  var firestore = FirebaseFirestore.instance;
  Geoflutterfire geo = Geoflutterfire();
  Location location = Location();

  void _addGeoPoint() async {
    // final auth = Provider.of<AuthProvider>(context, listen: false);
    // var posi= await location.longitude;
    // var pos = await location.getLocation();
    GeoFirePoint point =
        geo.point(latitude: location.latitude, longitude: location.longitude);

    return firestore
        .collection('locations')
        .doc(currentUserId)
        .set({'position': point.data});
  }
  */

//iiiiiiiiiiiippppppppppppppppppppppppppppppppppppp above
  int _currentIndex = 0;

  DateTime currentBackPressTime;

  PageController _pageController = PageController(initialPage: 0);
//iiiiiiiiiiiippppppppppppppppppppppppppppppppppppp below
/*
  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(seconds: 5), (timer) {
      _addGeoPoint();
    });
  }
  */

//iiiiiiiiiiiippppppppppppppppppppppppppppppppppppp above
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          body: PageView(
            controller: _pageController,
            onPageChanged: (int index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: <Widget>[
              TimelinePage(),
              SearchPage(),
              MessengerPage(),
              NotificationsPage(),
              ProfilePage(userId: currentUserModel.id),
              Chat(),
              GoogleMapScreen(),
              // MyGoogleMap(),
              // CovTracker(),
              // userMap()
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (int index) {
              setState(() {
                _pageController.jumpToPage(index);
              });
            },
            items: allNavigationItems.map((NavigationItem navigationItem) {
              return BottomNavigationBarItem(
                  icon: Icon(
                    navigationItem.icon,
                    color: appPrimaryColor,
                  ),
                  backgroundColor: appBackgroundLightColor,
                  title: Text(
                    navigationItem.title,
                    style: TextStyle(color: appPrimaryColor),
                  ));
            }).toList(),
          ),
        ),
        onWillPop: onBackPress);
  }

  Future<bool> onBackPress() {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime) > Duration(seconds: 2)) {
      currentBackPressTime = now;
      Fluttertoast.showToast(msg: "Press again to exit app");
      return Future.value(false);
    } else {
      return Future.value(true);
    }
  }
}
