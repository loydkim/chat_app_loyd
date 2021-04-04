import 'dart:async';

import 'package:chatapploydlab/Controllers/fb_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Controllers/fb_firestore.dart';
import 'Controllers/fb_storage.dart';
import 'Controllers/image_controller.dart';
import 'Controllers/utils.dart';
import 'subWidgets/chatListTile/mine_list_tile.dart';
import 'subWidgets/chatListTile/peer_user_list_tile.dart';
import 'subWidgets/chatListTile/string_list_tile.dart';
import 'subWidgets/common_widgets.dart';
import 'subWidgets/local_notification_view.dart';

class ChatRoom extends StatefulWidget {
  ChatRoom(this.myID,this.myName,this.myImageUrl,this.selectedUserToken, this.selectedUserID, this.chatID, this.selectedUserName, this.selectedUserThumbnail);

  String myID;
  String myName;
  String myImageUrl;
  String selectedUserToken;
  String selectedUserID;
  String chatID;
  String selectedUserName;
  String selectedUserThumbnail;

  @override _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> with WidgetsBindingObserver,LocalNotificationView {
  final TextEditingController _msgTextController = new TextEditingController();
  final ScrollController _chatListController = ScrollController();
  String messageType = 'text';
  int chatListLength = 20;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('didChangeAppLifecycleState');
    setState(() {
      switch(state) {
        case AppLifecycleState.resumed:
          FBCloudStore.instanace.updateMyChatListValues(widget.myID,widget.chatID,true);
          print('AppLifecycleState.resumed');
          break;
        case AppLifecycleState.inactive:
          print('AppLifecycleState.inactive');
          FBCloudStore.instanace.updateMyChatListValues(widget.myID,widget.chatID,false);
          break;
        case AppLifecycleState.paused:
          print('AppLifecycleState.paused');
          FBCloudStore.instanace.updateMyChatListValues(widget.myID,widget.chatID,false);
          break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FBCloudStore.instanace.updateMyChatListValues(widget.myID,widget.chatID,true);

    if(mounted){
      isShowLocalNotification = true;
      _savedChatId(widget.chatID);
      checkLocalNotification(localNotificationAnimation,widget.chatID);
    }
  }

  void localNotificationAnimation(List<dynamic> data){
    if(mounted){
      setState(() {
        if(data[1] == 1.0){
          localNotificationData = data[0];
        }
        localNotificationAnimationOpacity = data[1] as double;
      });
    }
  }

  Future<void> _savedChatId(String value) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("inRoomChatId", value);
  }

  @override
  void dispose() {
    isShowLocalNotification = false;
    FBCloudStore.instanace.updateMyChatListValues(widget.myID,widget.chatID,false);
    _savedChatId("");
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      color: Colors.white,
      child: SafeArea(
        top:false,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.selectedUserName),
            centerTitle: true,
          ),
          body: StreamBuilder<QuerySnapshot> (
              stream: FirebaseFirestore.instance.
                  collection('chatroom').
                  doc(widget.chatID).
                  collection(widget.chatID).
                  orderBy('timestamp',descending: false).
                  snapshots(),
              builder: (context,snapshot) {
                if (!snapshot.hasData) return LinearProgressIndicator();
                return Stack(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Expanded(
                          child: ListView(
                            reverse: true,
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(4.0,10,4,10),
                            controller: _chatListController,
                            children: addInstructionInSnapshot(snapshot.data.docs).map(_returnChatWidget).toList()
                          ),
                        ),
                        _buildTextComposer(),
                      ],
                    ),
                    localNotificationCard(size)
                  ],
                );
              }
            ),
          ),
      ),
    );
    // );
  }

  Widget _returnChatWidget(dynamic data){
    Widget _returnWidget;

    if(data is QueryDocumentSnapshot){
      if(data['idTo'] == widget.myID && data['isread'] == false) {
        if (data.reference != null) {
          FirebaseFirestore.instance.runTransaction((Transaction myTransaction) async {
            await myTransaction.update(data.reference, {'isread': true});
          });
        }
      }

      _returnWidget = data['idFrom'] == widget.selectedUserID ? peerUserListTile(context,
          widget.selectedUserName,
          widget.selectedUserThumbnail,
          data['content'],
          returnTimeStamp(data['timestamp']),
          data['type']) :
      mineListTile(context,
          data['content'],
          returnTimeStamp(data['timestamp']),
          data['isread'],
          data['type']);
    }else if(data is String){
      _returnWidget = stringListTile(data);
    }
    return _returnWidget;
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
                    ImageController.instance.cropImageFromFile().then((croppedFile) {
                      if (croppedFile != null) {
                        setState(() { messageType = 'image'; });
                        _saveUserImageToFirebaseStorage(croppedFile);
                      }else {
                        showAlertDialog(context,'Pick Image error');
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
      String takeImageURL = await FBStorage.instanace.sendImageToUserInChatRoom(croppedFile,widget.chatID);
      _handleSubmitted(takeImageURL);
    }catch(e) {
      showAlertDialog(context,'Error add user image to storage');
    }
  }

  Future<void> _handleSubmitted(String text) async {
    try {
      await FBCloudStore.instanace.sendMessageToChatRoom(widget.chatID,widget.myID,widget.selectedUserID,text,messageType);
      await FBCloudStore.instanace.updateUserChatListField(widget.selectedUserID, messageType == 'text' ? text : '(Photo)',widget.chatID,widget.myID,widget.selectedUserID);
      await FBCloudStore.instanace.updateUserChatListField(widget.myID, messageType == 'text' ? text : '(Photo)',widget.chatID,widget.myID,widget.selectedUserID);
      _getUnreadMSGCountThenSendMessage();
    }catch(e){
      showAlertDialog(context,'Error user information to database');
      _resetTextFieldAndLoading();
    }
  }

  Future<void> _getUnreadMSGCountThenSendMessage() async{
    try {
      int unReadMSGCount = await FBCloudStore.instanace.getUnreadMSGCount(widget.selectedUserID);
      await NotificationController.instance.sendNotificationMessageToPeerUser(unReadMSGCount, messageType, _msgTextController.text, widget.myName, widget.chatID, widget.selectedUserToken,widget.myImageUrl);
    }catch(e) {
      print(e.message);
    }
    _resetTextFieldAndLoading();
  }

  void _resetTextFieldAndLoading() {
    FocusScope.of(context).requestFocus(FocusNode());
    _msgTextController.text = '';
  }
}