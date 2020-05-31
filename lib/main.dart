import 'dart:io';

import 'package:chatapploydlab/Controllers/notificationController.dart';
import 'package:chatapploydlab/Controllers/pickImageController.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widgets/flutter_widgets.dart';

import 'Controllers/firebaseController.dart';
import 'Controllers/utils.dart';
import 'Model/const.dart';
import 'chatlist.dart';

void main() => runApp(MyApp());

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
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _nameTextController = TextEditingController();
  TextEditingController _introTextController = TextEditingController();
  File _userImageFile = File('');
  String _userImageUrlFromFB = '';

  bool _isLoading = true;

  @override
  void initState() {
    NotificationController.instance;
    _takeUserInformationFromFBDB();
    super.initState();
  }

  _takeUserInformationFromFBDB() async {
    FirebaseController.instanace.takeUserInformationFromFBDB().then((documents) {
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
      body: VisibilityDetector(
        key: Key("1"),
        onVisibilityChanged: ((visibility) {
          print(visibility.visibleFraction);
          if (visibility.visibleFraction == 1.0) {
            FirebaseController.instanace.getUnreadMSGCount();
          }
        }),
        child: Stack(
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
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    Padding(
                        padding: EdgeInsets.all(8),
                        child: GestureDetector(
                            onTap: () {
                              PickImageController.instance.cropImageFromFile().then((croppedFile) {
                                if (croppedFile != null) {
                                  setState(() {
                                    _userImageFile = croppedFile;
                                    _userImageUrlFromFB = '';
                                  });
                                } else {
                                  _showDialog('Pick Image error');
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
                    child: RaisedButton(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            'Go to Chat list',
                            style: TextStyle(fontSize: 28),
                          )
                        ],
                      ),
                      textColor: Colors.white,
                      color: Colors.green[700],
                      padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                      onPressed: () {
                        _saveDataToServer();
                      },
                    )),
                _youtubeTitle(),
                _youtubeLinkTitle(),
                _youtubeLinkAddress(),
                _youtubeImage()
              ],
            ),
            Positioned(
              // Loading view in the center.
              child: _isLoading
                  ? Container(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                      color: Colors.white.withOpacity(0.7),
                    )
                  : Container(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _youtubeTitle() {
    return Padding(
      padding: const EdgeInsets.only(left: 18.0, top: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Loyd Lab (Youtube)',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _youtubeLinkTitle() {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, top: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Youtube link: ',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _youtubeLinkAddress() {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, top: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () {
            launchURL();
          },
          child: Text(
            youtubeChannelLink,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[700],
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }

  Widget _youtubeImage() {
    return Expanded(child: Image.asset('images/youtube_screenshot.png'));
  }

  _saveDataToServer() {
    setState(() {
      _isLoading = true;
    });
    String alertString = checkValidUserData(_userImageFile, _userImageUrlFromFB,
        _nameTextController.text, _introTextController.text);
    if (alertString.trim() != '') {
      _showDialog(alertString);
    } else {
      _userImageUrlFromFB != ''
          ? FirebaseController.instanace.saveUserDataToFirebaseDatabase(randomIdWithName(_nameTextController.text),
          _nameTextController.text,_introTextController.text,_userImageUrlFromFB).then((data){
            _moveToChatList(data);
          })
          : FirebaseController.instanace.saveUserImageToFirebaseStorage(
          randomIdWithName(_nameTextController.text),_nameTextController.text,_introTextController.text,
          _userImageFile).then((data){
            _moveToChatList(data);
          });
    }
  }

  _moveToChatList(data) {
    setState(() { _isLoading = false; });
    if(data != null) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ChatList(data, _nameTextController.text)));
    }
    else { _showDialog('Save user data error'); }
  }

  _showDialog(String msg) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text(msg),
          );
        });
  }
}
