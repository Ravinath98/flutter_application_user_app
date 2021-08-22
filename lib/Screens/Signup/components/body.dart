//import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_app/LocationService_2.dart';
import 'package:flutter_app/Screens/Login/Login.dart';
import 'package:flutter_app/Screens/Signup/SignUp.dart';
import 'package:flutter_app/Service/Location.dart';
//import 'package:flutter_app/Service/LocationService.dart';

import 'package:flutter_app/components/RoundedButton.dart';
import 'package:flutter_app/components/RoundedPasswordFeild.dart';
import 'package:flutter_app/components/RoundedTextField.dart';
import 'package:flutter_app/components/TextFieldContainer.dart';
import 'package:flutter_app/constants.dart';
//import 'package:flutter_app/location_latitude.dart';
import 'package:flutter_app/location_longitude.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

//import '../../../initialLocation.dart';

final ref = FirebaseFirestore.instance.collection('users');

class Body extends StatefulWidget {
  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  Position currentposition;

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: 'Please enable Your Location Service');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: 'Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
          msg:
              'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      Placemark place = placemarks[0];

      setState(() {
        currentposition = position;
        //  currentAddress =
        //  "${place.locality}, ${place.postalCode}, ${place.country}";
      });
    } catch (e) {
      print(e);
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Container(
      height: size.height,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: size.height * 0.05,
                ),
                Text(
                  "Let's Get Started!",
                  style: TextStyle(
                      fontSize: size.height * 0.05, color: Colors.black),
                ),
                SizedBox(
                  height: size.height * 0.05,
                ),
                TextFieldContainer(
                  child: RoundedTextField(
                    icon: Icons.email,
                    controller: emailController,
                    hintText: "Email",
                  ),
                ),
                TextFieldContainer(
                  child: RoundedTextField(
                    icon: Icons.person,
                    controller: usernameController,
                    hintText: "Username",
                  ),
                ),
                TextFieldContainer(
                  child: RoundedPasswordField(
                    hintText: "Password",
                    controller: passwordController,
                  ),
                ),
                TextFieldContainer(
                  child: RoundedPasswordField(
                    hintText: "Repeat Password",
                    controller: repeatPasswordController,
                  ),
                ),
                TextFieldContainer(
                  child: RoundedTextField(
                    icon: Icons.category,
                    controller: productCategoryController,
                    hintText: "Product Category",
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    primary: Colors.blue,
                  ),
                  onPressed: () {
                    //getUserLocation();
                    // getUserCurrentLocationLat();
                    _determinePosition();
                    print('ok');
                    print(currentposition.latitude);
                    print(currentposition.longitude);

                    //  getUserCurrentLocationLon();
                  },
                  child: Text('TextButton'),
                ),

                ////////////////////////////////////

///////////////////////////////////////////////////////////
                RoundedButton(
                  text: "SIGN UP",
                  press: () {
                    if (isEmpty()) {
                      Fluttertoast.showToast(msg: "Please enter all fields");
                    } else if (repeatPasswordController.value.text !=
                        passwordController.value.text) {
                      Fluttertoast.showToast(msg: "Passwords do not match");
                      passwordController.clear();
                      repeatPasswordController.clear();
                    } else {
                      signUp(context);
                    }
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text("Already an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) {
                            return LoginScreen();
                          },
                        ));
                      },
                      child: Text(
                        "Login here",
                        style: TextStyle(color: appPrimaryColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextEditingController emailController = new TextEditingController();

  TextEditingController passwordController = new TextEditingController();

  TextEditingController usernameController = new TextEditingController();

  TextEditingController repeatPasswordController = new TextEditingController();

  TextEditingController productCategoryController = new TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void signUp(BuildContext context) {
    RegisterWithFirebase(context, emailController.value.text,
        usernameController.value.text, passwordController.value.text);
  }

  bool isEmpty() {
    if (emailController.value.text != "" &&
        usernameController.value.text != "" &&
        passwordController.value.text != "" &&
        repeatPasswordController.value.text != "" &&
        productCategoryController.value.text != "") {
      return false;
    }
    return true;
  }

  void RegisterWithFirebase(BuildContext context, String _email,
      String _username, String _password) async {
    try {
      final User user = (await _auth.createUserWithEmailAndPassword(
              email: _email, password: _password))
          .user;
      try {
        user.sendEmailVerification();
      } catch (e) {}

      addUserInfoToStorage(user);

      showDialog(
        context: context,
        builder: (_) => new AlertDialog(
          title: new Text("NOTIFICATION!!!"),
          content: new Text("Sign up success, verify your email before login"),
          actions: <Widget>[
            FlatButton(
              child: Text(
                "OK",
                style: TextStyle(color: appPrimaryColor),
              ),
              onPressed: () {
                //Navigator.of(context).pop();
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return LoginScreen();
                }));
              },
            )
          ],
        ),
      );
    } catch (error) {
      if (error.code == "invalid-email") {
        showDialog(
          context: context,
          builder: (_) => new AlertDialog(
            title: new Text("ERROR!!!"),
            content: new Text("Invalid email"),
            actions: <Widget>[
              FlatButton(
                child: Text(
                  "OK",
                  style: TextStyle(color: appPrimaryColor),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          ),
        );
        emailController.clear();
        usernameController.clear();
        passwordController.clear();
        repeatPasswordController.clear();
        productCategoryController.clear();
      } else if (error.code == "email-already-in-use") {
        showDialog(
          context: context,
          builder: (_) => new AlertDialog(
            title: new Text("ERROR!!!"),
            content: new Text("Email already in use"),
            actions: <Widget>[
              FlatButton(
                child: Text(
                  "OK",
                  style: TextStyle(color: appPrimaryColor),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          ),
        );
        emailController.clear();
        usernameController.clear();
        passwordController.clear();
        repeatPasswordController.clear();
        productCategoryController.clear();
      } else if (error.code == "weak_password") {
        showDialog(
          context: context,
          builder: (_) => new AlertDialog(
            title: new Text("ERROR!!!"),
            content: new Text("Your password is too weak"),
            actions: <Widget>[
              FlatButton(
                child: Text(
                  "OK",
                  style: TextStyle(color: appPrimaryColor),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          ),
        );
        passwordController.clear();
        repeatPasswordController.clear();
      } else {
        print("[SIGNUP ERROR] " + error.code);
      }
    }
  }

  Future<void> addUserInfoToStorage(User user) async {
    String userName = usernameController.text;
    String category = productCategoryController.text;
    //String initialLocation = getUserInitialLocation();

    var unverifiedUsers =
        FirebaseFirestore.instance.collection('unverifiedUsers');

    if (userName != null || userName.length != 0) {
      unverifiedUsers.doc(user.uid).set({
        "id": user.uid,
        "photoUrl":
            "", //FirebaseStorage.instance.ref().child("defaultProfileImage.png"),
        "email": user.email,
        "displayName": userName,
        // "initialLocation": initialLocation,
        //"lat": getUserCurrentLocationLatitude(),
        // "lon": getUserCurrentLocationLongitude(),
        "category": category,
        "lat": currentposition.latitude, //getUserCurrentLocationLat(),
        "lon": currentposition.longitude, //getUserCurrentLocationLon(),
        "bio": "",
        "followers": {},
        "following": {},
        "chatWiths": {},
        "chattingWith": null,
        "searchRecent": []
      });
    }
  }
}
