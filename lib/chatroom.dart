import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_widgets/flutter_widgets.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'Controllers/pickImageController.dart';
import 'Controllers/utils.dart';
import 'Model/const.dart';
import 'fullphoto.dart';

class ChatRoom extends StatefulWidget {
  ChatRoom(this.myID,this.myName,this.selectedUserToken, this.selectedUserID, this.chatID, this.selectedUserName, this.selectedUserThumbnail);

  String myID;
  String myName;
  String selectedUserToken;
  String selectedUserID;
  String chatID;
  String selectedUserName;
  String selectedUserThumbnail;

  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final TextEditingController _msgTextController = new TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    _setCurrentChatRoomID(widget.chatID);
    super.initState();
  }

  @override
  void dispose() {
    print('dispose');
    _setCurrentChatRoomID('none');
    super.dispose();
  }

  Future<void> _getUnreadMSGCount() async{
    try {
      int unReadMSGCount = 0;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String myId = (prefs.get('userId') ?? 'NoId');

      final QuerySnapshot chatListResult =
      await Firestore.instance.collection('users').document(myId).collection('chatlist').getDocuments();
      final List<DocumentSnapshot> chatListDocuments = chatListResult.documents;
      for(var data in chatListDocuments) {
        final QuerySnapshot unReadMSGDocument = await Firestore.instance.collection('chatroom').
        document(data['chatID']).
        collection(data['chatID']).
        where('idTo', isEqualTo: myId).
        where('isread', isEqualTo: false).
        getDocuments();

        final List<DocumentSnapshot> unReadMSGDocuments = unReadMSGDocument.documents;
        unReadMSGCount = unReadMSGCount + unReadMSGDocuments.length;
      }

      print('unread MSG count is $unReadMSGCount');
      FlutterAppBadger.updateBadgeCount(unReadMSGCount);
    }catch(e) {
      print(e.message);
    }
  }


  _setCurrentChatRoomID(value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentChatRoom', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Chat App - Chat Room'),
          centerTitle: true,
        ),
      body: VisibilityDetector(
        key: Key("1"),
        onVisibilityChanged: ((visibility) {
          print(visibility.visibleFraction);
          if (visibility.visibleFraction == 1.0) {
            _getUnreadMSGCount();
          }
        }),
        child: StreamBuilder<QuerySnapshot> (
          stream:Firestore.instance.collection('chatroom').document(widget.chatID).collection(widget.chatID).snapshots(),
          builder: (context,snapshot) {

            if (!snapshot.hasData) return LinearProgressIndicator();
            if (snapshot.hasData) {
              _getUnreadMSGCount();
            for (var data in snapshot.data.documents) {
              if(data['idTo'] == widget.myID) {
                  Firestore.instance.runTransaction((Transaction myTransaction) async {
                    await myTransaction.update(data.reference, {'isread': true});
                  });
                }
              }
            }
            return Column(
              children: <Widget>[
                Expanded(
                    child: ListView(
                      reverse: true,
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(4.0,10,4,10),
                      children: snapshot.data.documents.reversed.map((data) {
                        return data['idFrom'] == widget.selectedUserID ? _listItemOther(context,
                            widget.selectedUserName,
                            widget.selectedUserThumbnail,
                            data['content'],
                            returnTimeStamp(data['timestamp']),
                            data['type']) :
                          _listItemMine(context,
                            data['content'],
                            returnTimeStamp(data['timestamp']),
                            data['isread'],
                            data['type']);
                      }).toList()
                    ),
                ),
                _buildTextComposer(),
              ],
            );
          }
        ),
      )
    );
  }

  Widget _listItemOther(BuildContext context, String name, String thumbnail, String message, String time, String type) {
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.only(top:4.0),
      child: Container(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24.0),
                      child:
                      CachedNetworkImage(
                        imageUrl: thumbnail,
                        placeholder: (context, url) => Container(
                          transform: Matrix4.translationValues(0.0, 0.0, 0.0),
                          child: Container(
                              width: 60,
                              height: 60,
                              child: Center(child: new CircularProgressIndicator())),
                        ),
                        errorWidget: (context, url, error) => new Icon(Icons.error),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(name),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Padding(padding: const EdgeInsets.fromLTRB(0,4,0,8),
                          child: Container(
                            constraints: BoxConstraints(maxWidth: size.width - 150),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child:  Padding(
                              padding: EdgeInsets.all(type == 'text' ? 10.0:0),
                              child: Container(
                                child: type == 'text' ? Text(message,
                                  style: TextStyle(color: Colors.black),) :
                                Container(
                                  width: 160,
                                  height: 160,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                          context, MaterialPageRoute(builder: (context) => FullPhoto(url: message)));
                                    },
                                    child: CachedNetworkImage(
                                      imageUrl: message,
                                      placeholder: (context, url) => Container(
                                        transform: Matrix4.translationValues(0, 0, 0),
                                        child: Container(
                                            width: 60,
                                            height: 80,
                                            child: Center(child: new CircularProgressIndicator())),
                                      ),
                                      errorWidget: (context, url, error) => new Icon(Icons.error),
                                      width: 60,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom:14.0, left: 4),
                          child: Text(time,style: TextStyle(fontSize: 12),),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }

  Widget _listItemMine(BuildContext context, String message, String time, bool isRead, String type) {
    final size = MediaQuery.of(context).size;
    return Padding( padding: const EdgeInsets.only(top:2.0,right: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom:14.0, right: 2,left:4),
            child: Text(isRead ? '' : '1',style: TextStyle(fontSize: 12,color: Colors.yellow[900]),),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom:14.0, right: 4,left:8),
            child: Text(time,style: TextStyle(fontSize: 12),),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(padding: const EdgeInsets.fromLTRB(0,8,0,8),
                child: Container(
                  constraints: BoxConstraints(maxWidth: size.width - size.width*0.26),
                  decoration: BoxDecoration(
                    color: type == 'text' ? Colors.green[700] : Colors.transparent,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(type == 'text' ? 10.0:0),
                    child: Container(
                      child: type == 'text' ? Text(message,
                        style: TextStyle(color: Colors.white),) :
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context, MaterialPageRoute(builder: (context) => FullPhoto(url: message)));
                          },
                          child: CachedNetworkImage(
                            imageUrl: message,
                            placeholder: (context, url) => Container(
                              transform: Matrix4.translationValues(0, 0, 0),
                              child: Container(
                                  width: 60,
                                  height: 80,
                                  child: Center(child: new CircularProgressIndicator())),
                            ),
                            errorWidget: (context, url, error) => new Icon(Icons.error),
                            width: 60,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String messageType = 'text';

  Widget _buildTextComposer() {
    return new IconTheme(                                            //new
      data: new IconThemeData(color: Theme.of(context).accentColor), //new
      child: new Container(                                     //modified
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: new Row(
          children: <Widget>[
            new Container(
              margin: new EdgeInsets.symmetric(horizontal: 2.0),
              child: new IconButton(
                  icon: new Icon(Icons.photo,color: Colors.cyan[900],),
                  onPressed: () {
                    PickImageController.instance.cropImageFromFile().then((croppedFile) {
                      if (croppedFile != null) {
                        setState(() {
                          messageType = 'image';
                        });
                        _saveUserImageToFirebaseStorage(croppedFile);
                      }else {
                        _showDialog('Pick Image error');
                      }
                    });
                  }),
            ),
            new Flexible(
              child: new TextField(
                controller: _msgTextController,
                onSubmitted: _handleSubmitted,
                decoration: new InputDecoration.collapsed(
                    hintText: "Send a message"),
              ),
            ),

            new Container(
              margin: new EdgeInsets.symmetric(horizontal: 2.0),
              child: new IconButton(
                  icon: new Icon(Icons.send),
                  onPressed: () {
                    setState(() {
                      messageType = 'text';
                    });
                    _handleSubmitted(_msgTextController.text);
                  }),
            ),
          ],
        ),
      ),
    );
  }

  _takeImageFromLibrary() async{
    File imageFileFromLibrary = await ImagePicker.pickImage(source:ImageSource.gallery);
    _cropImageFromFile(imageFileFromLibrary);
  }

  _cropImageFromFile(File imageFile) async{
    File croppedFile = await ImageCropper.cropImage(
        sourcePath: imageFile.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        iosUiSettings: IOSUiSettings(
          minimumAspectRatio: 1.0,
        )
    );

    if (croppedFile != null) {
      setState(() {
        messageType = 'image';
      });
      _saveUserImageToFirebaseStorage(croppedFile);
    }
  }

  Future<void> _saveUserImageToFirebaseStorage(croppedFile) async {
    try {

      String imageTimeStamp = DateTime.now().millisecondsSinceEpoch.toString();

      String filePath = 'chatrooms/${widget.chatID}/$imageTimeStamp';
      final StorageReference storageReference = FirebaseStorage().ref().child(filePath);
      final StorageUploadTask uploadTask = storageReference.putFile(croppedFile);

      StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
      storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
        _saveImageToChatRoom(downloadUrl);
      }, onError: (err) {
        print(err.message);
        _showDialog('Error download user image');
      });

    }catch(e) {
      print(e.message);
      _showDialog('Error add user image to storage');
    }
  }

  Future<void> _saveImageToChatRoom(downloadUrl) async {
    try {
      Firestore.instance
          .collection('chatroom')
          .document(widget.chatID)
          .collection(widget.chatID)
          .document(DateTime.now().millisecondsSinceEpoch.toString()).setData({
        'idFrom': widget.myID,
        'idTo': widget.selectedUserID,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'content': downloadUrl,
        'type':messageType,
        'isread':false,
      });

      _updateChatRequestField(widget.selectedUserID, '(Photo)');
      _updateChatRequestField(widget.myID, '(Photo)');
      _getUnreadMSGCountThenSendMessage();
      setState(() {
        _isLoading = false;
      });
    }catch(e) {
      print(e.message);
      _showDialog('Error user information to database');
      setState(() {
        _isLoading = false;
      });
    }
  }

  _showDialog(String msg){
    showDialog(
        context: context,
        builder:(context) {
          return AlertDialog(
            content: Text(msg),
          );
        }
    );
  }

  Future<void> _handleSubmitted(String text) async {
    try {
      Firestore.instance
          .collection('chatroom')
          .document(widget.chatID)
          .collection(widget.chatID)
          .document(DateTime.now().millisecondsSinceEpoch.toString()).setData({
        'idFrom': widget.myID,
        'idTo': widget.selectedUserID,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'content': text,
        'type':messageType,
        'isread':false,
      });

      _updateChatRequestField(widget.selectedUserID, text);
      _updateChatRequestField(widget.myID, text);
      _getUnreadMSGCountThenSendMessage();

    }catch(e){
      print(e.message);
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text(e.message),
            );
          }
      );
      FocusScope.of(context).requestFocus(FocusNode());
      _msgTextController.text = '';
    }
  }

  Future<void> _getUnreadMSGCountThenSendMessage() async{
    try {
      int unReadMSGCount = 0;

      final QuerySnapshot chatListResult =
      await Firestore.instance.collection('users').document(widget.selectedUserID).collection('chatlist').getDocuments();
      final List<DocumentSnapshot> chatListDocuments = chatListResult.documents;
      for(var data in chatListDocuments) {
        final QuerySnapshot unReadMSGDocument = await Firestore.instance.collection('chatroom').
        document(data['chatID']).
        collection(data['chatID']).
        where('idTo', isEqualTo: widget.selectedUserID).
        where('isread', isEqualTo: false).
        getDocuments();

        final List<DocumentSnapshot> unReadMSGDocuments = unReadMSGDocument.documents;
        unReadMSGCount = unReadMSGCount + unReadMSGDocuments.length;
      }

      print('unread MSG count is $unReadMSGCount');
      sendAndRetrieveMessage(unReadMSGCount);
//      FlutterAppBadger.updateBadgeCount(unReadMSGCount);
    }catch(e) {
      print(e.message);
    }
  }


  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  Future<Map<String, dynamic>> sendAndRetrieveMessage(unReadMSGCount) async {

    await http.post(
      'https://fcm.googleapis.com/fcm/send',
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$firebaseCloudserverToken',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'body': messageType == 'text' ? '${_msgTextController.text}' : '(Photo)',
            'title': '${widget.myName}',
            'badge':'$unReadMSGCount'//'$unReadMSGCount'
          },
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': '1',
            'status': 'done',
            'chatroomid': widget.chatID,
          },
          'to': widget.selectedUserToken,
        },
      ),
    );

    final Completer<Map<String, dynamic>> completer =
    Completer<Map<String, dynamic>>();

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        completer.complete(message);
      },
    );
    FocusScope.of(context).requestFocus(FocusNode());
    _msgTextController.text = '';
    return completer.future;
  }

  Future _updateChatRequestField(String documentID,String lastMessage) async{
    Firestore.instance
        .collection('users')
        .document(documentID)
        .collection('chatlist')
        .document(widget.chatID)
        .setData({'chatID':widget.chatID,
         'chatWith':documentID == widget.myID ? widget.selectedUserID : widget.myID,
         'lastChat':lastMessage,
         'timestamp':DateTime.now().millisecondsSinceEpoch});
  }
}