import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/Service/Location.dart';
import 'package:flutter_app/components/RoundedButton.dart';
import 'package:geocoder/geocoder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_native_image/flutter_native_image.dart'; //updated.....

import '../../../constants.dart';
import '../../../main.dart';

class UploadPage extends StatefulWidget {
  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  File file;
  ImagePicker imagePicker = ImagePicker();
  Address address;
  Map<String, double> currentLocation = Map();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  bool uploading = false;
  List<AssetEntity> _selectedList = [];
  List<Widget> _photoList = [];
  int currentPage = 0;
  int lastPage;
  int maxSelection = 1;
  _handleScrollEvent(ScrollNotification scroll) {
    if (scroll.metrics.pixels / scroll.metrics.maxScrollExtent > 0.33) {
      if (currentPage != lastPage) {
        _fetchPhotos();
      }
    }
  }

  _fetchPhotos() async {
    lastPage = currentPage;
    var result = await PhotoManager.requestPermission();
    if (result) {
      //load the album list
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
          onlyAll: true, type: RequestType.image);
      List<AssetEntity> media =
          await albums[0].getAssetListPaged(currentPage, 60);
      List<Widget> temp = [];
      for (var asset in media) {
        temp.add(
          PhotoPickerItem(
              asset: asset,
              onSelect: (AssetEntity asset) {
                _getFile(asset);
              }),
        );
      }
      setState(() {
        _photoList.addAll(temp);
        currentPage++;
      });
    } else {
      // fail
      /// if result is fail, you can call `PhotoManager.openSetting();`  to open android/ios applicaton's setting to get permission
    }
  }

  @override
  initState() {
    //variables with location assigned as 0.0
    currentLocation['latitude'] = 0.0;
    currentLocation['longitude'] = 0.0;
    initPlatformState(); //method to call location
    super.initState();
    _fetchPhotos();
  }

  //method to get Location and save into variables
  initPlatformState() async {
    Address first = await getUserLocation();
    setState(() {
      address = first;
    });
  }

  _selectNewImage(BuildContext parentContext) async {
    File croppedFile; //changed here...
    Size size = MediaQuery.of(context).size;
    return showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            color: Color(0xFF737373),
            height: 235,
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
                    text: "Take a photo",
                    press: () async {
                      Navigator.pop(context);

                      PickedFile imageFile = await imagePicker.getImage(
                          source: ImageSource.camera,
                          maxWidth: 1920,
                          maxHeight: 1200,
                          imageQuality: 80);
                      if (imageFile != null) {
                        //changed below,,,,,,,,,,,,,
                        ImageProperties properties =
                            await FlutterNativeImage.getImageProperties(
                                imageFile.path);
                        //cropping image...
                        if (properties.height > properties.width) {
                          var yoffset =
                              (properties.height - properties.width) / 2;
                          croppedFile = await FlutterNativeImage.cropImage(
                              imageFile.path,
                              0,
                              yoffset.toInt(),
                              properties.width,
                              properties.width);
                        } else if (properties.width > properties.height) {
                          var xoffset =
                              (properties.width - properties.height) / 2;
                          croppedFile = await FlutterNativeImage.cropImage(
                              imageFile.path,
                              xoffset.toInt(),
                              0,
                              properties.height,
                              properties.height);
                        } else {
                          croppedFile = File(imageFile.path);
                        }
                        //Resize
                        File compressedFile =
                            await FlutterNativeImage.compressImage(
                                croppedFile.path,
                                quality: 100,
                                targetHeight: 600,
                                targetWidth: 600);

                        setState(() {
                          file = compressedFile;
                        });
                      }
                    },
                  ),
                  RoundedButton(
                    text: "Choose from Gallery",
                    press: () async {
                      Navigator.of(context).pop();
                      PickedFile imageFile = await imagePicker.getImage(
                          source: ImageSource.gallery,
                          maxWidth: 1920,
                          maxHeight: 1200,
                          imageQuality: 80);
                      if (imageFile != null) {
                        //changed below,,,,,,,,,,,,,
                        ImageProperties properties =
                            await FlutterNativeImage.getImageProperties(
                                imageFile.path);
                        //cropping image...
                        if (properties.height > properties.width) {
                          var yoffset =
                              (properties.height - properties.width) / 2;
                          croppedFile = await FlutterNativeImage.cropImage(
                              imageFile.path,
                              0,
                              yoffset.toInt(),
                              properties.width,
                              properties.width);
                        } else if (properties.width > properties.height) {
                          var xoffset =
                              (properties.width - properties.height) / 2;
                          croppedFile = await FlutterNativeImage.cropImage(
                              imageFile.path,
                              xoffset.toInt(),
                              0,
                              properties.height,
                              properties.height);
                        } else {
                          croppedFile = File(imageFile.path);
                        }
                        //Resize
                        File compressedFile =
                            await FlutterNativeImage.compressImage(
                                croppedFile.path,
                                quality: 100,
                                targetHeight: 600,
                                targetWidth: 600);
                        setState(() {
                          file = compressedFile;
                        });
                      }
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

  getImage(BuildContext context) async {
    file = null;
    await _selectNewImage(context);
  }

  @override
  Widget build(BuildContext context) {
    return file == null
        ? Scaffold(
            resizeToAvoidBottomInset: false,
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
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    file = null;
                  });
                  Navigator.of(context).pop();
                },
              ),
              title: const Text(
                "Choose Image",
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.add_circle_rounded),
                  onPressed: () {
                    getImage(context);
                  },
                )
              ],
            ),
            body: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scroll) {
                _handleScrollEvent(scroll);
                return;
              },
              child: GridView.builder(
                  itemCount: _photoList.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2),
                  itemBuilder: (BuildContext context, int index) {
                    return _photoList[index];
                  }),
            ))
        : Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
                backgroundColor: Color(0xffff008e),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      file = null;
                    });
                    Navigator.of(context).pop();
                  },
                ),
                title: const Text(
                  "New Post",
                  style: const TextStyle(color: Colors.white),
                ),
                actions: <Widget>[
                  FlatButton(
                      onPressed: () {
                        setState(() {
                          uploading = true;
                        });
                        uploadImage(file).then((String data) {
                          postToFireStore(
                              mediaUrl: data,
                              description: descriptionController.text,
                              location: locationController.text);
                        }).then((_) {
                          setState(() {
                            file = null;
                            uploading = false;
                          });
                        });
                        Navigator.pop(context);
                      },
                      child: IconButton(
                          icon: Icon(Icons.send,
                              color: Colors
                                  .white)) /*Text(
                      "Post",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0),
                    ),*/
                      )
                ]),
            body: ListView(
              children: <Widget>[
                PostForm(
                  imageFile: file,
                  descriptionController: descriptionController,
                  locationController: locationController,
                  loading: uploading,
                ),
                Divider(),
                (address == null)
                    ? Container()
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.only(right: 5.0, left: 5.0),
                        child: Row(
                          children: <Widget>[
                            buildLocationButton(address.featureName),
                            buildLocationButton(address.subLocality),
                            buildLocationButton(address.locality),
                            buildLocationButton(address.subAdminArea),
                            buildLocationButton(address.adminArea),
                            buildLocationButton(address.countryName),
                          ],
                        ))
              ],
            ),
          );
  }

  _getFile(AssetEntity asset) async {
    File temp = await asset.file;
    setState(() {
      file = temp;
    });
  }

  buildLocationButton(String locationName) {
    if (locationName != null ?? locationName.isNotEmpty) {
      return InkWell(
        onTap: () {
          locationController.text = locationName;
        },
        child: Center(
          child: Container(
            //width: 100.0,
            height: 30.0,
            padding: EdgeInsets.only(left: 8.0, right: 8.0),
            margin: EdgeInsets.only(right: 3.0, left: 3.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: Center(
              child: Text(
                locationName,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ),
      );
    } else {
      return Container();
    }
  }

/* void clearImage() {
    setState(() {
      file = null;
    });
  }*/
/*
  void postImage() {
    setState(() {
      uploading = true;
    });
    uploadImage(file).then((String data) {
      postToFireStore(
          mediaUrl: data,
          description: descriptionController.text,
          location: locationController.text);
    }).then((_) {
      setState(() {
        file = null;
        uploading = false;
      });
    });

  }*/
}

class PostForm extends StatelessWidget {
  final imageFile;
  final TextEditingController descriptionController;
  final TextEditingController locationController;
  final bool loading;

  PostForm(
      {this.imageFile,
      this.descriptionController,
      this.loading,
      this.locationController});

  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        loading
            ? LinearProgressIndicator()
            : Padding(padding: EdgeInsets.only(top: 0.0)),
        Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            CircleAvatar(
              backgroundImage: NetworkImage(currentUserModel.photoUrl),
            ),
            Container(
              width: 250.0,
              child: TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                    hintText: "Write a caption...", border: InputBorder.none),
              ),
            ),
            Container(
              height: 45.0,
              width: 45.0,
              child: AspectRatio(
                aspectRatio: 487 / 451,
                child: Container(
                  decoration: BoxDecoration(
                      image: DecorationImage(
                    fit: BoxFit.fill,
                    alignment: FractionalOffset.topCenter,
                    image: FileImage(imageFile),
                  )),
                ),
              ),
            ),
          ],
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.pin_drop),
          title: Container(
            width: 250.0,
            child: TextField(
              controller: locationController,
              decoration: InputDecoration(
                  hintText: "Where was this photo taken?",
                  border: InputBorder.none),
            ),
          ),
        )
      ],
    );
  }
}

Future<String> uploadImage(var imageFile) async {
  var uuid = Uuid().v1();
  Reference ref = FirebaseStorage.instance.ref().child("post_$uuid.jpg");
  UploadTask uploadTask = ref.putFile(imageFile);
  String downloadUrl = await (await uploadTask).ref.getDownloadURL();
  return downloadUrl;
}

void postToFireStore(
    {String mediaUrl, String location, String description}) async {
  var reference = FirebaseFirestore.instance.collection('posts');

  reference.add({
    "ownerId": currentUserModel.id,
    "displayName": currentUserModel.displayName,
    "location": location,
    "likes": {},
    "mediaUrl": mediaUrl,
    "description": description,
    "timestamp": DateTime.now(),
  }).then((DocumentReference doc) {
    String docId = doc.id;
    reference.doc(docId).update({"postId": docId});
  });
}

class PhotoPickerItem extends StatefulWidget {
  final AssetEntity asset;
  final bool Function(AssetEntity asset) onSelect;

  const PhotoPickerItem({this.asset, this.onSelect});

  @override
  _PhotoPickerItemState createState() => _PhotoPickerItemState();
}

class _PhotoPickerItemState extends State<PhotoPickerItem> {
  bool isSelected = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.asset.thumbDataWithSize(200, 200),
      builder: (BuildContext context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done)
          return GestureDetector(
            onTap: () {
              setState(() {
                // isSelected = !isSelected;
                isSelected = widget.onSelect(widget.asset);
              });
            },
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Image.memory(
                    snapshot.data,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          );
        return Container();
      },
    );
  }
}
