import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatapploydlab/Controllers/notificationController.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widgets/flutter_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Controllers/firebaseController.dart';
import 'Controllers/pickImageController.dart';
import 'Controllers/utils.dart';
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
  String messageType = 'text';
  bool _isLoading = false;

  @override
  void initState() {
    setCurrentChatRoomID(widget.chatID);
    FirebaseController.instanace.getUnreadMSGCount();
    super.initState();
  }

  @override
  void dispose() {
    setCurrentChatRoomID('none');
    super.dispose();
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
          print('ChatRoom Visibility code is '+'${visibility.visibleFraction}');
          if (visibility.visibleFraction == 1.0) {
            FirebaseController.instanace.getUnreadMSGCount();
          }
        }),
        child: StreamBuilder<QuerySnapshot> (
          stream:Firestore.instance.collection('chatroom').document(widget.chatID).collection(widget.chatID).snapshots(),
          builder: (context,snapshot) {
            if (!snapshot.hasData) return LinearProgressIndicator();
            if (snapshot.hasData) {
            for (var data in snapshot.data.documents) {
              if(data['idTo'] == widget.myID) {
                  if (data.reference != null) {
                    Firestore.instance.runTransaction((Transaction myTransaction) async {
                      await myTransaction.update(data.reference, {'isread': true});
                    });
                  }
                }
              }
            }
            return Stack(
              children: <Widget>[
                Column(
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
                ),
//                Positioned(
//                  // Loading view in the center.
//                  child: _isLoading
//                      ? Container(
//                    child: Center(
//                      child: CircularProgressIndicator(),
//                    ),
//                    color: Colors.white.withOpacity(0.7),
//                  )
//                      : Container(),
//                ),
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
                                _imageMessage(message)
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
                      _imageMessage(message)
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

  Widget _imageMessage(imageUrlFromFB) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => FullPhoto(url: imageUrlFromFB)));
        },
        child: CachedNetworkImage(
          imageUrl: imageUrlFromFB,
          placeholder: (context, url) => Container(
            transform: Matrix4.translationValues(0, 0, 0),
            child: Container( width: 60, height: 80,
                child: Center(child: new CircularProgressIndicator())),
          ),
          errorWidget: (context, url, error) => new Icon(Icons.error),
          width: 60,
          height: 80,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildTextComposer() {
    return new IconTheme(
      data: new IconThemeData(color: Theme.of(context).accentColor),
      child: new Container(
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
                        setState(() { messageType = 'image'; _isLoading = true; });
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
                    setState(() { messageType = 'text'; });
                    _handleSubmitted(_msgTextController.text);
                  }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveUserImageToFirebaseStorage(croppedFile) async {
    try {
      String takeImageURL = await FirebaseController.instanace.sendImageToUserInChatRoom(croppedFile,widget.chatID);
      _handleSubmitted(takeImageURL);
    }catch(e) {
      _showDialog('Error add user image to storage');
    }
  }

  Future<void> _handleSubmitted(String text) async {
    try {
      setState(() { _isLoading = true; });
      await FirebaseController.instanace.sendMessageToChatRoom(widget.chatID,widget.myID,widget.selectedUserID,text,messageType);
      await FirebaseController.instanace.updateChatRequestField(widget.selectedUserID, messageType == 'text' ? text : '(Photo)',widget.chatID,widget.myID,widget.selectedUserID);
      await FirebaseController.instanace.updateChatRequestField(widget.myID, messageType == 'text' ? text : '(Photo)',widget.chatID,widget.myID,widget.selectedUserID);
      _getUnreadMSGCountThenSendMessage();
    }catch(e){
      _showDialog('Error user information to database');
      _resetTextFieldAndLoading();
    }
  }

  Future<void> _getUnreadMSGCountThenSendMessage() async{
    try {
      int unReadMSGCount = await FirebaseController.instanace.getUnreadMSGCount(widget.selectedUserID);
      await NotificationController.instance.sendNotificationMessageToPeerUser(unReadMSGCount, messageType, _msgTextController.text, widget.myName, widget.chatID, widget.selectedUserToken);
    }catch(e) {
      print(e.message);
    }
    _resetTextFieldAndLoading();
  }

  _resetTextFieldAndLoading() {
    FocusScope.of(context).requestFocus(FocusNode());
    _msgTextController.text = '';
    setState(() { _isLoading = false; });
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
}