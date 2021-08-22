import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/Screens/MainScreen/pages/UploadPage.dart';
import 'package:flutter_app/constants.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/models/AppUser.dart';
import 'package:flutter_app/models/Post.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';

class TimelinePage extends StatefulWidget {
  @override
  TimelinePageState createState() => TimelinePageState();
}

class TimelinePageState extends State<TimelinePage>
    with AutomaticKeepAliveClientMixin<TimelinePage> {
  final double appBarHeight = AppBar().preferredSize.height;
  List<ImagePost> feedData = [];
  List<ImagePost> tempData = [];
  List<AppUser> followingUser;
  final imagePicker = ImagePicker();
  List<String> followings = [];
  @override
  void initState() {
    super.initState();
  }

  // ensures state is kept when switching pages
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        brightness: Brightness.dark,
        title: Text(
          appName,
          style: TextStyle(
              fontFamily: 'Billabong',
              fontSize: appBarHeight * 0.7,
              fontStyle: FontStyle.italic),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[appPrimaryColor, appPrimaryColor2],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_rounded),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => UploadPage()));
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: buildNewFeed(),
      ),
    );
  }

  buildNewFeed() {
    followings = currentUserModel.following.keys.toList();
    followings.add(currentUserModel.id);
    if (feedData != null) {
      return StreamBuilder<List<ImagePost>>(
          stream: _getfeed(followings),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Sorry! We have an error."));
            } else if (snapshot.hasData) {
              final data = snapshot.data;

              feedData = data;
              feedData.sort((a, b) => b.timestamp.compareTo(a.timestamp));
              //feedData.sort((a,b) => a.timestamp - b.timestamp);
            }
            return ListView(
              children: feedData,
            );
          });
    } else {
      return Container(
          alignment: FractionalOffset.center,
          child: CircularProgressIndicator());
    }
  }

  Future<Null> _refresh() async {
    buildNewFeed();
    setState(() {});
    return;
  }

  Stream<List<ImagePost>> _getfeed(List<String> followingsList) {
    var snapshots = FirebaseFirestore.instance.collection('posts').snapshots();
    return snapshots.map((snapshot) => snapshot.docs
        .map(
          (snapshot) => ImagePost.fromMap(snapshot.data()),
        )
        .toList());
  }
}
