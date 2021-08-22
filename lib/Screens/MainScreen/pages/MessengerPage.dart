import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/Screens/MainScreen/pages/Chat.dart';
import 'package:flutter_app/Screens/MainScreen/pages/SearchChatUser.dart';
import 'package:flutter_app/components/Loading.dart';
import 'package:flutter_app/constants.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/models/AppUser.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MessengerPage extends StatefulWidget {
  @override
  MessengerPageState createState() => MessengerPageState();
}

class MessengerPageState extends State<MessengerPage>
    with AutomaticKeepAliveClientMixin<MessengerPage> {
  @override
  void initState() {
    listScrollController.addListener(scrollListener);
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification notification = message.notification;
      AndroidNotification android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channel.description,
                color: Colors.blue,
                playSound: true,
                icon: '@mipmap/ic_launcher',
              ),
            ));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      RemoteNotification notification = message.notification;
      AndroidNotification android = message.notification?.android;
      if (notification != null && android != null) {
        showDialog(
            context: context,
            builder: (_) {
              return AlertDialog(
                title: Text(notification.title),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(notification.body)],
                  ),
                ),
              );
            });
      }
    });
  }

  void showNotification() {
    flutterLocalNotificationsPlugin.show(
        0,
        "LevArt Message",
        "You have a new message",
        NotificationDetails(
            android: AndroidNotificationDetails(
                channel.id, channel.name, channel.description,
                importance: Importance.high,
                color: Colors.blue,
                playSound: true,
                icon: '@mipmap/ic_launcher')));
  }

  int lastMessageTimeStamp = DateTime.now().millisecondsSinceEpoch;

  @override
  void dispose() {
    listScrollController.removeListener(scrollListener);
    super.dispose();
  }

  // ensures state is kept when switching pages
  @override
  bool get wantKeepAlive => true;

  final ScrollController listScrollController = ScrollController();

  int _limit = 20;
  int _limitIncrement = 20;
  bool isLoading = false;

  void scrollListener() {
    setState(() {});

    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  Widget buildItem(BuildContext context, DocumentSnapshot document) {
    String id = currentUserModel.id;
    String peerId = document.data()['id'];
    String groupChatId =
        (id.hashCode <= peerId.hashCode) ? '$id-$peerId' : '$peerId-$id';
    return Container(
      height: 65,
      child: FlatButton(
        child: Row(
          children: <Widget>[
            Material(
              child: document.data()['photoUrl'] != ""
                  ? CircleAvatar(
                      backgroundImage:
                          NetworkImage(document.data()['photoUrl']),
                      radius: 25.0,
                    )
                  : Image.asset(
                      "assets/images/defaultProfileImage.png",
                      height: 50,
                      width: 50,
                    ),
              borderRadius: BorderRadius.all(Radius.circular(50.0)),
              clipBehavior: Clip.hardEdge,
            ),
            Flexible(
              child: Container(
                child: Column(
                  children: <Widget>[
                    Container(
                      child: Text(
                        document.data()['displayName'],
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      alignment: Alignment.centerLeft,
                      margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                    ),
                    StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('messages')
                            .doc(groupChatId)
                            .collection(groupChatId)
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            String fromUser =
                                (snapshot.data.docs[0].data()['idFrom'] !=
                                        currentUserModel.id)
                                    ? ""
                                    : "You: ";
                            if (DateTime.now().millisecondsSinceEpoch <=
                                    (int.parse(snapshot.data.docs[0]
                                            .data()['timestamp']) +
                                        5000) &&
                                snapshot.data.docs[0].data()['idFrom'] !=
                                    currentUserModel.id &&
                                currentUserModel.chattingWith != peerId) {
                              showNotification();
                            }

                            return Container(
                              child: Text(
                                '${fromUser}${snapshot.data.docs[0].data()['content']}',
                                overflow: TextOverflow.ellipsis,
                              ),
                              alignment: Alignment.centerLeft,
                              margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                            );
                          } else {
                            return Container(height: 0);
                          }
                        }),
                  ],
                ),
                margin: EdgeInsets.only(left: 20.0),
              ),
            ),
          ],
        ),
        onPressed: () {
          currentUserModel =
              AppUser.changeChattingWith(currentUserModel, peerId);
          FirebaseFirestore.instance
              .collection('users')
              .doc(id)
              .update({'chattingWith': peerId});
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => Chat(
                        peerId: document.id,
                        peerAvatar: document.data()['photoUrl'],
                        peerName: document.data()['displayName'],
                      )));
        },
        color: appPrimaryLightColor,
        padding: EdgeInsets.fromLTRB(25.0, 10.0, 25.0, 10.0),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
      margin: EdgeInsets.only(bottom: 10.0, left: 5.0, right: 5.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        brightness: Brightness.dark,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[appPrimaryColor, appPrimaryColor2],
            ),
          ),
        ),
        automaticallyImplyLeading: false,
        title: Text("Message"),
        actions: [
          IconButton(
              icon: Icon(Icons.edit_rounded),
              padding: EdgeInsets.only(right: 10.0),
              onPressed: () {
                setState(() {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) {
                      return SearchUserChat();
                    },
                  ));
                });
              }),
        ],
      ),
      body: Container(
        child: Stack(
          children: <Widget>[
            // List
            Container(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('chatWiths.${currentUserModel.id}',
                        isNotEqualTo: false)
                    .orderBy('chatWiths.${currentUserModel.id}',
                        descending: true)
                    .limit(_limit)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(appPrimaryColor),
                      ),
                    );
                  } else if (snapshot.data.docs.length == 0) {
                    return Center(
                      child: Text("You don't have any messages"),
                    );
                  } else {
                    return ListView.builder(
                      padding: EdgeInsets.all(10.0),
                      itemBuilder: (context, index) {
                        final itemPositionOffset = index *
                            75; //itemSize (height) = 65, + margin(10) = 75
                        final difference =
                            listScrollController.offset - itemPositionOffset;
                        final percent = 1 - (difference / 75);
                        double opacity = percent;
                        if (opacity < 0) {
                          opacity = 0;
                        } else if (opacity > 1) {
                          opacity = 1;
                        }
                        return Opacity(
                          opacity: opacity,
                          child: Transform(
                              alignment: Alignment.bottomCenter,
                              transform: Matrix4.identity()
                                ..scale(opacity, opacity),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: buildItem(
                                    context, snapshot.data.docs[index]),
                              )),
                        );
                      },
                      itemCount: snapshot.data.docs.length,
                      controller: listScrollController,
                    );
                  }
                },
              ),
            ),

            // Loading
            Positioned(
              child: isLoading ? const Loading() : Container(),
            )
          ],
        ),
      ),
    );
  }
}
