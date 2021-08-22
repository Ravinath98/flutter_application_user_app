import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/Screens/MainScreen/pages/ProfilePage.dart';
import 'package:flutter_app/constants.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/models/Post.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsPage extends StatefulWidget {
  @override
  NotificationsPageState createState() => NotificationsPageState();
}

Widget mediaPreview;
String notifiationText;
String pushNotiContext;
ImagePost imagePost;

class NotificationsPageState extends State<NotificationsPage>
    with AutomaticKeepAliveClientMixin<NotificationsPage> {
  bool isMute = false;
  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage noti) {
      RemoteNotification notification = noti.notification;
      AndroidNotification android = noti.notification?.android;
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
                playSound: false,
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

  void showPushNotification() {
    isNotiShow = true;
    flutterLocalNotificationsPlugin.show(
        0,
        "LevArt Notification",
        pushNotiContext,
        NotificationDetails(
            android: AndroidNotificationDetails(
                channel.id, channel.name, channel.description,
                importance: Importance.high,
                color: Colors.blue,
                playSound: false,
                icon: '@mipmap/ic_launcher')));
  }

  List<NotificationItems> listNoti = [];
  bool isNotiShow = false;
  int lastNoti = DateTime.now().microsecondsSinceEpoch;
  buildNotifications() {
    return Container(
      child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('feed')
              .doc(currentUserModel.id)
              .collection("items")
              .orderBy("timestamp", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data.docs.length == 0)
              return Container(
                  alignment: FractionalOffset.center,
                  padding: const EdgeInsets.only(top: 10.0),
                  child: CircularProgressIndicator());
            else {
              Timestamp temp = snapshot.data.docs[0].data()['timestamp'];
              if (temp.microsecondsSinceEpoch > lastNoti) {
                isNotiShow = false;
                lastNoti = temp.microsecondsSinceEpoch;
                switch (snapshot.data.docs[0].data()['type']) {
                  case "like":
                    pushNotiContext = "someone liked your post.";
                    break;
                  case "comment":
                    pushNotiContext = "someone commented to your post.";
                    break;
                  case "follow":
                    pushNotiContext = "someone is following you.";
                    break;
                }
              }
              if (!isMute && !isNotiShow) showPushNotification();
              return ListView.builder(
                  itemCount: snapshot.data.docs.length,
                  itemBuilder: (context, index) {
                    return NotificationItems.fromDocument(
                        snapshot.data.docs[index]);
                  });
            }
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        title: Text("Notifications"),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isMute = !isMute;
              });
            },
            icon: Icon(
              isMute ? Icons.notifications_off : Icons.notifications,
            ),
          ),
        ],
      ),
      body: buildNotifications(),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class NotificationItems extends StatelessWidget {
  final String mediaUrl;
  final String postId;
  final Timestamp timestamp;
  final String type;
  final String userId;
  final String userProfileImg;
  final String commentData;
  final String userName;

  NotificationItems(
      {this.mediaUrl,
      this.postId,
      this.timestamp,
      this.type,
      this.userId,
      this.userProfileImg,
      this.commentData,
      this.userName});

  factory NotificationItems.fromDocument(DocumentSnapshot doc) {
    return NotificationItems(
      mediaUrl: doc.data()['mediaUrl'],
      postId: doc.data()['postId'],
      timestamp: doc.data()['timestamp'],
      commentData: doc.data()['commentData'],
      type: doc.data()['type'],
      userId: doc.data()['userId'],
      userName: doc.data()['username'],
      userProfileImg: doc.data()['userProfileImg'],
    );
  }
  getImagePostbyId(postId) async {
    ImagePost post;
    var snap =
        await FirebaseFirestore.instance.collection('posts').doc(postId).get();
    post = ImagePost.fromDocument(snap);
    imagePost = post;
  }

  mediaReviewConfig(context) {
    getImagePostbyId(postId);
    if (type == "like" || type == "comment") {
      mediaPreview = GestureDetector(
        onTap: () => openImagePost(context, imagePost),
        child: Container(
          height: 50.0,
          width: 50.0,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                fit: BoxFit.cover,
                image: CachedNetworkImageProvider(mediaUrl),
              )),
            ),
          ),
        ),
      );
    } else {
      mediaPreview = Text('');
    }
    if (type == "like") {
      notifiationText = " liked your post.";
    } else if (type == "follow") {
      notifiationText = " is following you.";
    } else if (type == "comment") {
      notifiationText = " commented: $commentData.";
    } else {
      notifiationText = "Error: Unknown type '$type'";
    }
  }

  @override
  Widget build(BuildContext context) {
    mediaReviewConfig(context);
    return Padding(
        padding: EdgeInsets.only(bottom: 2.0),
        child: Container(
          color: Colors.white60,
          child: ListTile(
            title: GestureDetector(
              onTap: () => openProfile(context, userId),
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                          text: userName,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                        text: '$notifiationText',
                      )
                    ]),
              ),
            ),
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(userProfileImg),
            ),
            subtitle: Text(
              timeago.format(timestamp.toDate()),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: mediaPreview,
          ),
        ));
  }
}
