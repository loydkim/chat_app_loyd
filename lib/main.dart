import 'dart:io';

import 'package:chatapploydlab/Controllers/fb_messaging.dart';
import 'package:chatapploydlab/Controllers/image_controller.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_widgets/flutter_widgets.dart';

import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'Controllers/fb_firestore.dart';
import 'Controllers/fb_storage.dart';
import 'Controllers/utils.dart';
import 'chatlist.dart';
import 'subWidgets/common_widgets.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  print('Handling a background message ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await firebase_core.Firebase.initializeApp();
  // Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  /// Update the iOS foreground notification presentation options to allow
  /// heads up notifications.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _nameTextController = TextEditingController();
  TextEditingController _introTextController = TextEditingController();
  File _userImageFile = File('');
  String _userImageUrlFromFB = '';

  bool _isLoading = true;

  @override
  void initState() {
    NotificationController.instance.takeFCMTokenWhenAppLaunch();
    NotificationController.instance.initLocalNotification();
    setCurrentChatRoomID('none');
    _takeUserInformationFromFBDB();
    super.initState();
  }

  _takeUserInformationFromFBDB() async {
    FBCloudStore.instanace.takeUserInformationFromFBDB().then((documents) {
      if (documents.length > 0) {
        _nameTextController.text = documents[0]['name'];
        _introTextController.text = documents[0]['intro'];
        setState(() {
          _userImageUrlFromFB = documents[0]['userImageUrl'];
        });
      }
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat App - Add user'),
        centerTitle: true,
      ),
      body:
      // VisibilityDetector(
      //   key: Key("1"),
      //   onVisibilityChanged: ((visibility) {
      //     print(visibility.visibleFraction);
      //     if (visibility.visibleFraction == 1.0) {
      //       FirebaseController.instanace.getUnreadMSGCount();
      //     }
      //   }),
      //   child:
        Stack(
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 18.0, top: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Your Information.',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    Padding(
                        padding: EdgeInsets.all(8),
                        child: GestureDetector(
                          onTap: () {
                            ImageController.instance.cropImageFromFile().then((croppedFile) {
                              if (croppedFile != null) {
                                setState(() {
                                  _userImageFile = croppedFile;
                                  _userImageUrlFromFB = '';
                                });
                              } else {
                                showAlertDialog(context,'Pick Image error');
                              }
                            });
                          },
                          child: Container(
                            width: 140,
                            height: 160,
                            child: Card(
                              child: _userImageUrlFromFB != ''
                                  ? Image.network(_userImageUrlFromFB)
                                  : (_userImageFile.path != '')
                                      ? Image.file(_userImageFile,
                                          fit: BoxFit.fill)
                                      : Icon(Icons.add_photo_alternate,
                                          size: 60, color: Colors.grey[700]),
                            ),
                          ))),
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                icon: Icon(Icons.account_circle),
                                labelText: 'Name',
                                hintText: 'Type Name'),
                            controller: _nameTextController,
                          ),
                          TextFormField(
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                icon: Icon(Icons.note),
                                labelText: 'Intro',
                                hintText: 'Type Intro'),
                            controller: _introTextController,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 10, 20, 10),
                    child: MaterialButton(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text('Go to Chat list', style: TextStyle(fontSize: 28),)
                        ],
                      ),
                      textColor: Colors.white,
                      color: Colors.green[700],
                      padding: EdgeInsets.all(10),
                      onPressed: () => _saveDataToServer(),
                    )),

              ],
            ),
            // youtubePromotion(),
            loadingCircle(_isLoading),
          ],
        ),
      );
    // );
  }

  void _saveDataToServer() {
    setState(() => _isLoading = true);
    String alertString = checkValidUserData(_userImageFile, _userImageUrlFromFB, _nameTextController.text, _introTextController.text);
    if (alertString.trim() != '') {
      showAlertDialog(context,alertString);
    } else {
      _userImageUrlFromFB != ''
          ? FBCloudStore.instanace.saveUserDataToFirebaseDatabase(randomIdWithName(_nameTextController.text),
          _nameTextController.text,_introTextController.text,_userImageUrlFromFB).then((data){
            _moveToChatList(data);
          })
          : FBStorage.instanace.saveUserImageToFirebaseStorage(
          randomIdWithName(_nameTextController.text),_nameTextController.text,_introTextController.text,
          _userImageFile).then((data){
            _moveToChatList(data);
          });
    }
  }

  void _moveToChatList(data) {
    setState(() => _isLoading = false);
    if(data != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ChatList(data, _nameTextController.text,_userImageUrlFromFB)));
    }
    else { showAlertDialog(context,'Save user data error'); }
  }
}
