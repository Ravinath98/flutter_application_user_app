import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapScreen extends StatefulWidget {
  //const GoogleMapScreen({ Key? key }) : super(key: key);

  @override
  _GoogleMapScreenState createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  GoogleMapController myController;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  void initMarker(specify, specifyId) async {
    var markerIdval = specifyId;
    final MarkerId markerId = MarkerId(markerIdval);
    final Marker marker = Marker(
        markerId: markerId,
        position: LatLng(specify["lat"], specify["lon"]),
        infoWindow: InfoWindow(title: specify["displayName"]));
    setState(() {
      markers[markerId] = marker;
    });
  }

  getMarkerData() async {
    FirebaseFirestore.instance.collection('users').get().then((myLocationData) {
      if (myLocationData.docs.isNotEmpty) {
        for (int i = 0; i < myLocationData.docs.length; i++) {
          initMarker(myLocationData.docs[i].data(), myLocationData.docs[i].id);
        }
      }
    });
  }

  void initState() {
    getMarkerData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
          markers: Set<Marker>.of(markers.values),
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: LatLng(8.2656, 80.6558),
            zoom: 14.0,
          ),
          onMapCreated: (GoogleMapController controller) {
            myController = controller;
          }),
    );
    // );
  }
}
