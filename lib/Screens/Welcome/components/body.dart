import 'package:flutter/material.dart';
import 'package:flutter_app/Screens/Login/Login.dart';
import 'package:flutter_app/Screens/Signup/SignUp.dart';
import 'package:flutter_app/components/RoundedButton.dart';
import 'package:flutter_app/constants.dart';

class Body extends StatelessWidget {
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
                SizedBox(height: size.height * 0.1),
                Text(
                  appName,
                  style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: size.height * 0.1,
                      color: appPrimaryColor,
                      fontStyle: FontStyle.italic),
                ),
                SizedBox(height: size.height * 0.1),
                RoundedButton(
                  text: "LOGIN",
                  press: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return LoginScreen();
                        },
                      ),
                    );
                  },
                ),
                RoundedButton(
                  text: "SIGN UP",
                  color: appPrimaryLightColor,
                  textColor: Colors.black,
                  press: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return SignUpScreen();
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
