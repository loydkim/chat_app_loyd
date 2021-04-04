import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Controllers/fb_messaging.dart';
import 'Controllers/image_controller.dart';
import 'Controllers/utils.dart';
import 'chatroom.dart';
import 'subWidgets/common_widgets.dart';
import 'subWidgets/local_notification_view.dart';

class ChatList extends StatefulWidget {
  ChatList(this.myID, this.myName,this.myImageUrl);

  String myID;
  String myName;
  String myImageUrl;

  @override _ChatList createState() => _ChatList();
}

class _ChatList extends State<ChatList> with LocalNotificationView{

  @override
  void initState() {
    super.initState();
    NotificationController.instance.updateTokenToServer();
    if(mounted){
      checkLocalNotification(localNotificationAnimation,"");
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat App - Chat List'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> userSnapshot) {
          if (!userSnapshot.hasData) return loadingCircleForFB();
          return countChatListUsers(widget.myID, userSnapshot) > 0
          ? Stack(
            children: [
              ListView(
                  children: userSnapshot.data.docs.map((userData) {
                  if (userData['userId'] == widget.myID) {
                    return Container();
                  } else {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.myID)
                        .collection('chatlist')
                        .where('chatWith', isEqualTo: userData['userId'])
                        .snapshots(),
                      builder: (context, chatListSnapshot) {
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: ImageController.instance.cachedImage(userData['userImageUrl']),
                          ),
                          title: Text(userData['name']),
                          subtitle: Text((chatListSnapshot.hasData && chatListSnapshot.data.docs.length >0)
                              ? chatListSnapshot.data.docs[0]['lastChat']
                              : userData['intro']),
                          trailing: Padding(padding: const EdgeInsets.fromLTRB(0, 8, 4, 4),
                            child: (chatListSnapshot.hasData && chatListSnapshot.data.docs.length > 0)
                            ? Container(
                              width: 60,
                              height: 50,
                              child: Column(
                                children: <Widget>[
                                  Text((chatListSnapshot.hasData && chatListSnapshot.data.docs.length >0)
                                    ? readTimestamp(chatListSnapshot.data.docs[0]['timestamp'])
                                    : '',style: TextStyle(fontSize: size.width * 0.03),
                                  ),
                                  Padding(
                                      padding:const EdgeInsets.fromLTRB( 0, 5, 0, 0),
                                      child: CircleAvatar(
                                        radius: 9,
                                        child: Text(chatListSnapshot.data.docs[0].data()['badgeCount'] == null ? '' : ((chatListSnapshot.data.docs[0].data()['badgeCount'] != 0
                                          ? '${chatListSnapshot.data.docs[0].data()['badgeCount']}'
                                          : '')),
                                        style: TextStyle(fontSize: 10),),
                                        backgroundColor: chatListSnapshot.data.docs[0].data()['badgeCount'] == null ? Colors.transparent : (chatListSnapshot.data.docs[0]['badgeCount'] != 0
                                          ? Colors.red[400]
                                          : Colors.transparent),
                                        foregroundColor:Colors.white,
                                      )
                                  ),
                                ],
                              ),
                            ) : Text('')),
                            onTap: () => _moveTochatRoom(userData['FCMToken'],userData['userId'],userData['name'],userData['userImageUrl']),
                      );
                    });
                  }
                }).toList()),
              localNotificationCard(size)
            ],
          )
          : Container(
              child: Center(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.forum, color: Colors.grey[700],size: 64,),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      'There are no users except you.\nPlease use other devices to chat.',
                      style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              )),
            );
        }),
      );
  }

  Future<void> _moveTochatRoom(selectedUserToken, selectedUserID,selectedUserName, selectedUserThumbnail) async {
    try {
      String chatID = makeChatId(widget.myID, selectedUserID);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoom(
            widget.myID,
            widget.myName,
            widget.myImageUrl,
            selectedUserToken,
            selectedUserID,
            chatID,
            selectedUserName,
            selectedUserThumbnail)));
    } catch (e) {
      print(e.message);
    }
  }
}
