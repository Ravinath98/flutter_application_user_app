import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart';

class AppUser {
  final String email;
  final String id;
  final String photoUrl;
  final String displayName;
  final String category;
  final double lat;
  final double lon;
  final String role;
  ////final double lat;
  //final double lon;
  // final String initialLocation; ////////changed here....
  final String bio;
  final Map followers;
  final Map following;
  final Map chatWiths;
  final List<String> searchRecent;
  final String chattingWith;

  const AppUser(
      {this.id,
      this.photoUrl,
      this.email,
      this.displayName,
      this.category,
      this.lat,
      this.lon,
      this.role,
      //   this.initialLocation, ////////changed here....
      // this.lat,
      //  this.lon,
      this.bio,
      this.followers,
      this.following,
      this.chatWiths,
      this.searchRecent,
      this.chattingWith});

  factory AppUser.changeChattingWith(AppUser currentUser, String chattingWith) {
    return AppUser(
        email: currentUser.email,
        photoUrl: currentUser.photoUrl,
        id: currentUser.id,
        displayName: currentUser.displayName,
        //   initialLocation: currentUser.initialLocation, ////////changed here....
        //  lat: currentUser.lat,
        //  lon: currentUser.lon,
        category: currentUser.category,
        lat: currentUser.lat,
        lon: currentUser.lon,
        role: currentUser.role,
        bio: currentUser.bio,
        followers: currentUser.followers,
        following: currentUser.following,
        chatWiths: currentUser.chatWiths,
        chattingWith: chattingWith,
        searchRecent: currentUser.searchRecent);
  }

  factory AppUser.fromDocument(DocumentSnapshot document) {
    return AppUser(
        email: document.data()['email'],
        photoUrl: document.data()['photoUrl'],
        id: document.id,
        displayName: document.data()['displayName'],
        //initialLocation: document['initialLocation'], ////////changed here....
        // lat: document['lat'],
        // lon: document['lon'],
        category: document.data()['category'],
        lat: document.data()['lat'],
        lon: document.data()['lon'],
        role: document.data()['role'],
        bio: document.data()['bio'],
        followers: document.data()['followers'],
        following: document.data()['following'],
        chatWiths: document.data()['chatWiths'],
        chattingWith: document.data()['chattingWith'],
        searchRecent: List.from(document.data()['searchRecent']));
  }
  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
        email: data['email'],
        photoUrl: data['photoUrl'],
        id: data['id'],
        displayName: data['displayName'],
        //initialLocation: data['initialLocation'], ////////changed here....
        // lat: data['lat'],
        // lon: data['lon'],
        category: data['category'],
        lat: data['lat'],
        lon: data['lon'],
        role: data['role'],
        bio: data['bio'],
        followers: data['followers'],
        following: data['following'],
        chatWiths: data['chatWiths'],
        chattingWith: data['chattingWith'],
        searchRecent: List.from(data['searchRecent']));
  }
}
