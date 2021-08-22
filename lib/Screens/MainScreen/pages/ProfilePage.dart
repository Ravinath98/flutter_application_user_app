import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/Screens/MainScreen/pages/Chat.dart';
import 'package:flutter_app/Screens/Welcome/Welcome.dart';
import 'package:flutter_app/components/RoundedButton.dart';
import 'package:flutter_app/location_longitude.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/models/AppUser.dart';
import 'package:flutter_app/constants.dart';
import 'package:flutter_app/Screens/MainScreen/pages/EditProfilePage.dart';
import 'package:flutter_app/models/Post.dart';
import 'package:flutter_app/pay.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({@required this.userId});

  final String userId;

  @override
  ProfilePageState createState() => ProfilePageState(this.userId);
}

class ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin<ProfilePage> {
  final String profileId;

  String currentUserId = FirebaseAuth.instance.currentUser.uid;

  String view = "grid"; // default view
  bool isFollowing = false;
  bool followButtonClicked = false;
  int postCount = 0;
  int followerCount = 0;
  int followingCount = 0;

  String userName = "";

  ProfilePageState(this.profileId);

  @override
  void initState() {
    super.initState();
    updateProfileData();
    StripeService.init();
  }

  var response;
  Future<void> payWithCard() async {
    ProgressDialog dialog = ProgressDialog(context);
    dialog.style(message: 'Please wait...');
    await dialog.show();
    response =
        await StripeService.payWithNewCard(currency: 'USD', amount: '500');
    await dialog.hide();
    print('response : ${response.success}');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(response.message),
      duration: Duration(milliseconds: response.success == true ? 1200 : 3000),
    ));
  }

  Future<void> updateProfileData() async {
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get()
        .then((querySnapshot) {
      setState(() {
        userName = querySnapshot['displayName'];
      });
    });
  }

  EditProfilePage editPage = new EditProfilePage();
  openEditProfilePage() {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return editPage;
      },
    ));
  }

  followUser() {
    print('following user');
    setState(() {
      this.isFollowing = true;
      followButtonClicked = true;
    });

    FirebaseFirestore.instance.doc("users/$profileId").update({
      'followers.$currentUserId': true
      //firestore plugin doesnt support deleting, so it must be nulled / falsed
    });

    FirebaseFirestore.instance.doc("users/$currentUserId").update({
      'following.$profileId': true
      //firestore plugin doesnt support deleting, so it must be nulled / falsed
    });

    //updates activity feed
    FirebaseFirestore.instance
        .collection("feed")
        .doc(profileId)
        .collection("items")
        .doc(currentUserId)
        .set({
      "ownerId": profileId,
      "username": currentUserModel.displayName,
      "userId": currentUserId,
      "type": "follow",
      "userProfileImg": currentUserModel.photoUrl,
      "timestamp": DateTime.now()
    });
  }

  unfollowUser() {
    setState(() {
      isFollowing = false;
      followButtonClicked = true;
    });

    FirebaseFirestore.instance.doc("users/$profileId").update({
      'followers.$currentUserId': false
      //firestore plugin doesnt support deleting, so it must be nulled / falsed
    });

    FirebaseFirestore.instance.doc("users/$currentUserId").update({
      'following.$profileId': false
      //firestore plugin doesnt support deleting, so it must be nulled / falsed
    });
  }

  changeView(String viewName) {
    setState(() {
      view = viewName;
    });
  }

  int _countFollowings(Map followings) {
    int count = 0;

    void countValues(key, value) {
      if (value) {
        count += 1;
      }
    }

    followings.forEach(countValues);

    return count;
  }

  // ensures state is kept when switching pages
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // reloads state when opened again
    final Size size = MediaQuery.of(context).size;

    Column buildStatColumn(String label, int number) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            number.toString(),
            style: TextStyle(
                fontSize: size.width * 0.05, fontWeight: FontWeight.bold),
          ),
          Container(
              margin: const EdgeInsets.only(top: 4.0),
              child: Text(
                label,
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: size.width * 0.035,
                    fontWeight: FontWeight.w400),
              ))
        ],
      );
    }

    Container buildFollowButton(
        {String text,
        Color backgroundcolor,
        Color textColor,
        Color borderColor,
        Function function}) {
      return Container(
        padding: EdgeInsets.only(top: 2.0),
        child: FlatButton(
            onPressed: function,
            child: Container(
              decoration: BoxDecoration(
                  color: backgroundcolor,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(5.0)),
              alignment: Alignment.center,
              child: Text(text,
                  style:
                      TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              width: size.width * 0.6,
              height: 27.0,
            )),
      );
    }

    Container buildProfileFollowButton(BuildContext _context) {
      // viewing your own profile - should show edit button
      if (currentUserId == profileId) {
        print("Build edit button");
        return buildFollowButton(
          text: "Edit Profile",
          backgroundcolor: Colors.white,
          textColor: Colors.black,
          borderColor: Colors.grey,
          function: openEditProfilePage,
        );
      }

      // already following user - should show unfollow button
      if (isFollowing) {
        return buildFollowButton(
          text: "Unfollow",
          backgroundcolor: Colors.white,
          textColor: Colors.black,
          borderColor: Colors.grey,
          function: unfollowUser,
        );
      }

      // does not follow user - should show follow button
      if (!isFollowing) {
        return buildFollowButton(
          text: "Follow",
          backgroundcolor: Colors.blue,
          textColor: Colors.white,
          borderColor: Colors.blue,
          function: followUser,
        );
      }

      return buildFollowButton(
          text: "loading...",
          backgroundcolor: Colors.white,
          textColor: Colors.black,
          borderColor: Colors.grey);
    }

/////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////////////////

    Row buildImageViewButtonBar() {
      Color isActiveButtonColor(String viewName) {
        if (view == viewName) {
          return appPrimaryColor2;
        } else {
          return Colors.black26;
        }
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.grid_on, color: isActiveButtonColor("grid")),
            onPressed: () {
              changeView("grid");
            },
          ),
          IconButton(
            icon: Icon(Icons.list, color: isActiveButtonColor("feed")),
            onPressed: () {
              changeView("feed");
            },
          ),
        ],
      );
    }

    Container buildUserPosts() {
      Future<List<ImagePost>> getPosts() async {
        List<ImagePost> posts = [];
        var snap = await FirebaseFirestore.instance
            .collection('posts')
            .where('ownerId', isEqualTo: profileId)
            .orderBy("timestamp")
            .get();
        for (var doc in snap.docs) {
          posts.add(ImagePost.fromDocument(doc));
        }
        setState(() {
          postCount = snap.docs.length;
        });

        return posts.reversed.toList();
      }

      return Container(
          child: FutureBuilder<List<ImagePost>>(
        future: getPosts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Container(
                alignment: FractionalOffset.center,
                padding: const EdgeInsets.only(top: 10.0),
                child: CircularProgressIndicator());
          else if (view == "grid") {
            //build the grid
            return GridView.count(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
                padding: const EdgeInsets.all(0.5),
                mainAxisSpacing: 1.5,
                crossAxisSpacing: 1.5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: snapshot.data.map((ImagePost post) {
                  return GridTile(child: ImageTile(post));
                }).toList());
          } else if (view == "feed") {
            return Column(
                children: snapshot.data.map((ImagePost post) {
              return post;
            }).toList());
          } else {
            return Container();
          }
        },
      ));
    }

    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(profileId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data.exists) {
            return Container(
                alignment: FractionalOffset.center,
                child: CircularProgressIndicator());
          } else {
            AppUser user = AppUser.fromDocument(snapshot.data);

            if (user.followers.containsKey(currentUserId) &&
                user.followers[currentUserId] &&
                followButtonClicked == false) {
              isFollowing = true;
            }

            return Scaffold(
                appBar: (currentUserModel.id == this.profileId)
                    ? AppBar(
                        brightness: Brightness.dark,
                        automaticallyImplyLeading: false,
                        flexibleSpace: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: <Color>[
                                appPrimaryColor,
                                appPrimaryColor2
                              ],
                            ),
                          ),
                        ),
                        title: Container(
                          child: Text(user.displayName),
                        ),
                        actions: [
                          IconButton(
                              icon: Icon(Icons.settings),
                              onPressed: () {
                                openUserOption(context);
                              })
                        ],
                      )
                    : AppBar(
                        brightness: Brightness.dark,
                        automaticallyImplyLeading: true,
                        flexibleSpace: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: <Color>[
                                appPrimaryColor,
                                appPrimaryColor2
                              ],
                            ),
                          ),
                        ),
                        title: Container(
                          child: Text(user.displayName),
                        ),
                        actions: [
                          IconButton(
                              onPressed: () {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return Chat(
                                      peerId: profileId,
                                      peerAvatar: user.photoUrl,
                                      peerName: user.displayName);
                                }));
                              },
                              icon: Icon(Icons.message))
                        ],
                      ),
                body: ListView(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              (user.photoUrl != "")
                                  ? CircleAvatar(
                                      radius: size.width * 0.11,
                                      backgroundColor: Colors.grey,
                                      backgroundImage:
                                          NetworkImage(user.photoUrl),
                                    )
                                  : Image.asset(
                                      "assets/images/defaultProfileImage.png",
                                      width: size.width * 0.23,
                                      height: size.width * 0.23,
                                      fit: BoxFit.fitHeight),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: <Widget>[
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: <Widget>[
                                        buildStatColumn("posts", postCount),
                                        buildStatColumn("followers",
                                            _countFollowings(user.followers)),
                                        buildStatColumn("following",
                                            _countFollowings(user.following)),
                                      ],
                                    ),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: <Widget>[
                                          buildProfileFollowButton(context)
                                        ]),
                                    ////////////////////////////
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: <Widget>[
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              primary: Colors.blue,
                                            ),
                                            onPressed: () async {
                                              await payWithCard();
                                            },
                                            child: Text('Pay \$5'),
                                          ),
                                        ]),
                                    ////////////////////////
                                  ],
                                ),
                              )
                            ],
                          ),
                          Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(top: 15.0),
                              child: Text(
                                user.bio,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              )),
                        ],
                      ),
                    ),
                    Divider(),
                    buildImageViewButtonBar(),
                    Divider(height: 0.0),
                    buildUserPosts(),
                  ],
                ));
          }
        });
  }
}

class ImageTile extends StatelessWidget {
  final ImagePost imagePost;

  ImageTile(this.imagePost);

  clickedImage(BuildContext context) {
    openImagePost(context, imagePost);
  }

  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => clickedImage(context),
        child: Image.network(imagePost.mediaUrl, fit: BoxFit.cover));
  }
}

Future<void> _signOut(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signOut().then((_) {
      currentUserModel = null;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
        builder: (context) {
          return WelcomeScreen();
        },
      ), (route) => false);
    });
  } catch (e) {}
}

openUserOption(BuildContext parentContext) {
  return showModalBottomSheet(
      context: parentContext,
      builder: (context) {
        return Container(
          color: Color(0xFF737373),
          height: 170,
          child: Container(
            decoration: BoxDecoration(
                color: appPrimaryLightColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(29),
                  topRight: const Radius.circular(29),
                )),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.remove, color: Colors.grey),
                SizedBox(
                  height: 10,
                ),
                RoundedButton(
                  text: "Log out",
                  press: () {
                    _signOut(context);
                  },
                ),
                RoundedButton(
                  text: "Cancel",
                  press: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      });
}

void openProfile(BuildContext context, String userId) {
  Navigator.of(context)
      .push(MaterialPageRoute<bool>(builder: (BuildContext context) {
    return ProfilePage(userId: userId);
  }));
}
