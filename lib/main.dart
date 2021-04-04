import 'dart:io';

import 'package:chatapploydlab/Controllers/fb_messaging.dart';
import 'package:chatapploydlab/Controllers/image_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'Controllers/fb_auth.dart';
import 'Controllers/fb_firestore.dart';
import 'Controllers/fb_storage.dart';
import 'Controllers/utils.dart';
import 'chatlist.dart';
import 'subWidgets/common_widgets.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await firebase_core.Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    badge: true,
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

class _MyHomePageState extends State<MyHomePage> with FBAuth{
  TextEditingController _emailTextController = TextEditingController();
  TextEditingController _nameTextController = TextEditingController();
  TextEditingController _introTextController = TextEditingController();
  File _userImageFile = File('');
  String _userImageUrlFromFB = '';

  bool _isLoading = true;
  User _user;
  String _userId;

  @override
  void initState() {
    super.initState();
    NotificationController.instance.takeFCMTokenWhenAppLaunch();
    NotificationController.instance.initLocalNotification();
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() {
    FirebaseAuth.instance.authStateChanges().listen((User user) {
      if(user != null){
        _userId = user.uid;
        _takeUserInformationFromFBDB(user);
      }else{
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  _takeUserInformationFromFBDB(User user) async {
    FBCloudStore.instanace.takeUserInformationFromFBDB().then((documents) {
      if (documents.length > 0) {
        _emailTextController.text = documents[0].data()['email'] ?? '';
        _nameTextController.text = documents[0]['name'];
        _introTextController.text = documents[0]['intro'];
        _userId = documents[0]['userId'];

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
                              icon: Icon(Icons.mail),
                              labelText: 'Email',
                              hintText: 'Type Email'),
                          controller: _emailTextController,
                        ),
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
                    onPressed: () => _checkUserStatus(),
                  )),

            ],
          ),
          // youtubePromotion(),
          loadingCircle(_isLoading),
        ],
      ),
    );
  }

  void _checkUserStatus() async{
    setState(() => _isLoading = true);
    String alertString = checkValidUserData(_userImageFile, _userImageUrlFromFB, _nameTextController.text, _introTextController.text);
    if (alertString.trim() != '') {
      showAlertDialog(context,alertString);
    } else {
      if(_userId == null){
        _userId = await addUserUsingEmail(context,_emailTextController.text) ?? randomIdWithName(_nameTextController.text);
      }
      _updateFBdata();
    }
  }

  void _updateFBdata(){
    if(_userImageFile.path != ''){
      FBStorage.instanace.saveUserImageToFirebaseStorage(_emailTextController.text,
          _userId,_nameTextController.text,_introTextController.text,
          _userImageFile).then((userData){
        _moveToChatList(userData);
      });
    }else{
      FBCloudStore.instanace.saveUserDataToFirebaseDatabase(_emailTextController.text,_userId,_nameTextController.text,_introTextController.text,_userImageUrlFromFB).then((userData){
        _moveToChatList(userData);
      });
    }
  }

  void _moveToChatList(List<String> userData) {
    setState(() => _isLoading = false);
    if(userData != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ChatList(userData[0], _nameTextController.text,_userImageUrlFromFB == '' ? userData[1] : _userImageUrlFromFB)));
    }
    else { showAlertDialog(context,'Save user data error'); }
  }
}
