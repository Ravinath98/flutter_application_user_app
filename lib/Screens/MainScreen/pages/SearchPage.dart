import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app/Screens/MainScreen/pages/ProfilePage.dart';
import 'package:flutter_app/constants.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/models/Post.dart';

class SearchPage extends StatefulWidget {
  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage>
    with TickerProviderStateMixin<SearchPage> {
  final double appBarHeight = AppBar().preferredSize.height;
  TabController _tabController;
  String searchHintText;
  TextEditingController _searchTermController;
  String searchTerm = "";

  @override
  void initState() {
    _tabController = new TabController(length: 3, vsync: this);
    _searchTermController = new TextEditingController();
    _tabController.addListener(TabControllerListener);
    _searchTermController.addListener(SearchControllerListener);
    searchHintText = 'Search';
    super.initState();
  }

  @override
  void dispose() {
    _searchTermController.removeListener(SearchControllerListener);
    _tabController.removeListener(TabControllerListener);
    super.dispose();
  }

  SearchControllerListener() {
    print('[LISTENER]');
    if (_searchTermController.value.text != "" && _tabController.index == 0) {
      _tabController.animateTo(1);
    }
    setState(() {
      searchTerm = _searchTermController.value.text;
    });
  }

  TabControllerListener() {
    if (_tabController.indexIsChanging) {
      if (_tabController.index == 1 && _tabController.previousIndex == 0) {
      } else {
        _searchTermController.clear();
      }
    }

    if (_tabController.index == 0) {
      setState(() {
        searchHintText = 'Search';
      });
    } else if (_tabController.index == 1) {
      setState(() {
        searchHintText = 'Search accounts';
      });
    } else if (_tabController.index == 2) {
      setState(() {
        searchHintText = 'Search Category';
      });
    } else {
      setState(() {
        searchHintText = 'Search places';
      });
    }
  }

  Container buildSearchResult() {
    final Size size = MediaQuery.of(context).size;
    QuerySnapshot temp;

    if (_tabController.index == 1) {
      // search accounts
      return Container(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .where("displayName", isGreaterThanOrEqualTo: searchTerm)
              .snapshots(),
          builder: (context, snapshot) {
            return (searchTerm == "")
                ? Center(
                    child: Text("Looking for soneone"),
                  )
                : (snapshot.connectionState == ConnectionState.waiting)
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: snapshot.data.docs.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot doc = snapshot.data.docs[index];
                          var data = doc.data();
                          return FlatButton(
                              onPressed: () {
                                String tempProfileId = data['id'];
                                if (currentUserModel.searchRecent.length == 0) {
                                  currentUserModel.searchRecent
                                      .add(tempProfileId);
                                  FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(currentUserModel.id)
                                      .update({
                                    'searchRecent':
                                        currentUserModel.searchRecent
                                  });
                                } else if (!currentUserModel.searchRecent
                                    .contains(tempProfileId)) {
                                  currentUserModel.searchRecent
                                      .insert(0, tempProfileId);
                                  FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(currentUserModel.id)
                                      .update({
                                    'searchRecent':
                                        currentUserModel.searchRecent
                                  });
                                } else if (currentUserModel.searchRecent
                                    .contains(tempProfileId)) {
                                  currentUserModel.searchRecent
                                      .remove(tempProfileId);
                                  currentUserModel.searchRecent
                                      .insert(0, tempProfileId);
                                  FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(currentUserModel.id)
                                      .update({
                                    'searchRecent':
                                        currentUserModel.searchRecent
                                  });
                                }

                                print("[ID] " + tempProfileId);
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return ProfilePage(userId: tempProfileId);
                                }));
                              },
                              child: Column(children: <Widget>[
                                SizedBox(
                                  height: size.height * 0.01,
                                ),
                                Row(
                                  children: <Widget>[
                                    SizedBox(
                                      width: (data['photoUrl'] != "") ? 25 : 20,
                                    ),
                                    (data['photoUrl'] != "")
                                        ? CircleAvatar(
                                            radius: size.width * 0.06,
                                            backgroundImage:
                                                NetworkImage(data['photoUrl']),
                                          )
                                        : Image.asset(
                                            "assets/images/defaultProfileImage.png",
                                            width: size.width * 0.14,
                                            height: size.width * 0.14,
                                            fit: BoxFit.fitHeight),
                                    SizedBox(
                                      width: (data['photoUrl'] != "") ? 25 : 20,
                                    ),
                                    Text(
                                      data['displayName'],
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.normal),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: size.height * 0.01,
                                ),
                              ]));
                        },
                      );
          },
        ),
      );
    } else if (_tabController.index == 2) {
      //search places
      return Container(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("posts")
              .where("location", isGreaterThanOrEqualTo: searchTerm)
              //.orderBy("likes", )
              .snapshots(),
          builder: (context, snapshot) {
            return (searchTerm == "")
                ? Center(
                    child: Text("Looking for somewhere"),
                  )
                : (snapshot.connectionState == ConnectionState.waiting)
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: snapshot.data.docs.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot doc = snapshot.data.docs[index];
                          var data = doc.data();
                          return Padding(
                            padding: EdgeInsets.only(top: 2.0),
                            child: FlatButton(
                              onPressed: () {
                                ImagePost tempPost =
                                    ImagePost.fromDocument(doc);
                                openImagePost(context, tempPost);
                              },
                              child: ListTile(
                                title: Text(
                                  data['displayName'],
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                trailing: Container(
                                  height: 50.0,
                                  width: 50.0,
                                  child: AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: Container(
                                      decoration: BoxDecoration(
                                          image: DecorationImage(
                                        fit: BoxFit.cover,
                                        image: CachedNetworkImageProvider(
                                            data['mediaUrl']),
                                      )),
                                    ),
                                  ),
                                ),
                                subtitle: Text(
                                  data['description'],
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          );
                        },
                      );
          },
        ),
      );
    } else {
      //search recent
      if (currentUserModel.searchRecent != null &&
          currentUserModel.searchRecent.length != 0) {
        return Container(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .where("id", whereIn: currentUserModel.searchRecent)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              return (!snapshot.hasData)
                  ? Center(
                      child: Text("Search someone"),
                    )
                  : (snapshot.connectionState == ConnectionState.waiting)
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: snapshot.data.docs.length,
                          itemBuilder: (context, index) {
                            DocumentSnapshot doc;
                            for (var _doc in snapshot.data.docs) {
                              if (_doc.data()['id'] ==
                                  currentUserModel.searchRecent[index]) {
                                doc = _doc;
                                break;
                              }
                            }
                            var data = doc.data();
                            return FlatButton(
                                onPressed: () {
                                  final String tempProfileId = data['id'];
                                  if (index != 0) {
                                    currentUserModel.searchRecent
                                        .remove(tempProfileId);
                                    currentUserModel.searchRecent
                                        .insert(0, tempProfileId);
                                    FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(currentUserModel.id)
                                        .update({
                                      'searchRecent':
                                          currentUserModel.searchRecent
                                    });
                                  }

                                  print("[ID] " + tempProfileId);
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return ProfilePage(userId: tempProfileId);
                                  }));
                                },
                                child: Column(children: <Widget>[
                                  SizedBox(
                                    height: size.height * 0.01,
                                  ),
                                  Row(
                                    children: <Widget>[
                                      SizedBox(
                                        width:
                                            (data['photoUrl'] != "") ? 25 : 20,
                                      ),
                                      (data['photoUrl'] != "")
                                          ? CircleAvatar(
                                              radius: size.width * 0.06,
                                              backgroundImage: NetworkImage(
                                                  data['photoUrl']),
                                            )
                                          : Image.asset(
                                              "assets/images/defaultProfileImage.png",
                                              width: size.width * 0.14,
                                              height: size.width * 0.14,
                                              fit: BoxFit.fitHeight),
                                      SizedBox(
                                        width:
                                            (data['photoUrl'] != "") ? 25 : 20,
                                      ),
                                      Text(
                                        data['displayName'],
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.normal),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: size.height * 0.01,
                                  ),
                                ]));
                          },
                        );
            },
          ),
        );
      } else {
        return Container(
          child: Center(
            child: Text("Search someone"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        bottom: TabBar(
          indicatorColor: Colors.white,
          controller: _tabController,
          tabs: [
            Tab(
              text: "Recent",
            ),
            Tab(
              text: "Accounts",
            ),
            Tab(
              text: "Places",
            ),
            Tab(
              text: "Categories",
            )
          ],
        ),
        automaticallyImplyLeading: false,
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
        title: Container(
          height: appBarHeight * 0.8,
          margin: EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: appPrimaryLightColor,
            borderRadius: BorderRadius.circular(29),
          ),
          child: TextField(
            controller: _searchTermController,
            cursorColor: appPrimaryColor,
            decoration: InputDecoration(
              hintStyle: TextStyle(fontSize: appBarHeight * 0.4),
              hintText: searchHintText,
              suffixIcon: Icon(Icons.search),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.only(left: 5, bottom: 5, top: 5, right: 5),
            ),
          ),
        ),
      ),
      body: buildSearchResult(),
    );
  }
}
