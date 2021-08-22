import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/constants.dart';
import "dart:async";
import '../../../main.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentPage extends StatefulWidget {
  final String postId;
  final String postOwner;
  final String postMediaUrl;

  const CommentPage({this.postId, this.postOwner, this.postMediaUrl});

  @override
  _CommentPageState createState() => _CommentPageState(
      postId: this.postId,
      postOwner: this.postOwner,
      postMediaUrl: this.postMediaUrl);
}

class _CommentPageState extends State<CommentPage> {
  final String postId;
  final String postOwner;
  final String postMediaUrl;

  bool didFetchComments = false;
  List<Comment> fetchedComments = [];

  final TextEditingController _commentController = TextEditingController();

  _CommentPageState({this.postId, this.postOwner, this.postMediaUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
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
        title: Text('Comments'),
      ),
      body: buildPage(),
    );
  }

  Widget buildPage() {
    return Column(
      children: [
        Expanded(
          child: buildComments(),
        ),
        Divider(),
        ListTile(
          title: TextFormField(
            controller: _commentController,
            decoration: InputDecoration(labelText: 'Write a comment...'),
            onFieldSubmitted: addComment,
          ),
          trailing: OutlineButton(
            onPressed: () {
              addComment(_commentController.text);
            },
            borderSide: BorderSide.none,
            child: Text("Post"),
          ),
        ),
      ],
    );
  }

  Widget buildComments() {
    if (this.didFetchComments == false) {
      return FutureBuilder<List<Comment>>(
          future: getComments(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return Container(
                  alignment: FractionalOffset.center,
                  child: CircularProgressIndicator());

            this.didFetchComments = true;
            this.fetchedComments = snapshot.data;
            return ListView(
              children: snapshot.data,
            );
          });
    } else {
      // for optimistic updating
      return ListView(children: this.fetchedComments);
    }
  }

  Future<List<Comment>> getComments() async {
    List<Comment> comments = [];

    QuerySnapshot data = await FirebaseFirestore.instance
        .collection("comments")
        .doc(postId)
        .collection("comments_in_post")
        .orderBy("timestamp")
        .get();
    data.docs.forEach((DocumentSnapshot doc) {
      comments.add(Comment.fromDocument(doc));
    });
    return comments;
  }

  addComment(String comment) {
    _commentController.clear();
    FirebaseFirestore.instance
        .collection("comments")
        .doc(postId)
        .collection("comments_in_post")
        .add({
      "comment": comment,
      "timestamp": Timestamp.now(),
      "avatarUrl": currentUserModel.photoUrl,
      "userId": currentUserModel.id,
      "displayName": currentUserModel.displayName,
    });

    //adds to postOwner's activity feed
    FirebaseFirestore.instance
        .collection("feed")
        .doc(postOwner)
        .collection("items")
        .add({
      "userId": currentUserModel.id,
      "type": "comment",
      "userProfileImg": currentUserModel.photoUrl,
      "commentData": comment,
      "timestamp": Timestamp.now(),
      "postId": postId,
      "mediaUrl": postMediaUrl,
      "username": currentUserModel.displayName,
    });

    // add comment to the current listview for an optimistic update
    setState(() {
      fetchedComments = List.from(fetchedComments)
        ..add(Comment(
          comment: comment,
          timestamp: Timestamp.now(),
          avatarUrl: currentUserModel.photoUrl,
          userId: currentUserModel.id,
          displayName: currentUserModel.displayName,
        ));
    });
  }
}

class Comment extends StatelessWidget {
  final String displayName;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;

  Comment(
      {this.displayName,
      this.userId,
      this.avatarUrl,
      this.comment,
      this.timestamp});

  factory Comment.fromDocument(DocumentSnapshot document) {
    var data = document.data();
    return Comment(
      displayName: data['displayName'],
      userId: data['userId'],
      comment: data["comment"],
      timestamp: data["timestamp"],
      avatarUrl: data["avatarUrl"],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        /* ListTile(
          title: Text(comment),
          leading: CircleAvatar(
            backgroundImage: NetworkImage(avatarUrl),
          ),
        ),
        Divider()*/
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20, right: 10, top: 20),
              width: 40,
              height: 40,
              child: CircleAvatar(
                backgroundImage: NetworkImage(avatarUrl),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(top: 20, right: 5),
                      child: Text(displayName,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 20, right: 5),
                      child: Text(comment,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          )),
                    )
                  ],
                ),
/*                RichText(
                    text: TextSpan(
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        children: <TextSpan>[
                      TextSpan(
                          text: displayName,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          )),
                      TextSpan(text: ' '),
                      TextSpan(
                          text: comment,
                          style: TextStyle(fontSize: 16, color: Colors.black))
                    ])),*/
                Container(
                  margin: EdgeInsets.only(right: 10, top: 4),
                  child: Text(
                    timeago.format(timestamp.toDate()),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
