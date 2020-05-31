import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatapploydlab/Controllers/firebaseController.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widgets/flutter_widgets.dart';

import 'Controllers/utils.dart';
import 'chatroom.dart';

class ChatList extends StatefulWidget {
  ChatList(this.myID, this.myName);

  String myID;
  String myName;

  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat App - Chat List'),
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
        child: StreamBuilder<QuerySnapshot>(
            stream: Firestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return Container(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                  color: Colors.white.withOpacity(0.7),
                );
              return countChatListUsers(widget.myID, snapshot) > 0
              ? ListView(
                  children: snapshot.data.documents.map((data) {
                  if (data['userId'] == widget.myID) {
                    return Container();
                  } else {
                    return StreamBuilder<QuerySnapshot>(
                      stream: Firestore.instance
                          .collection('users')
                          .document(widget.myID)
                          .collection('chatlist')
                          .where('chatWith', isEqualTo: data['userId'])
                          .snapshots(),
                      builder: (context, chatListSnapshot) {
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: CachedNetworkImage(
                              imageUrl: data['userImageUrl'],
                              placeholder: (context, url) => Container(
                                transform:
                                    Matrix4.translationValues(0, 0, 0),
                                    child: Container(width: 60,height: 80,
                                      child: Center(child:new CircularProgressIndicator())),),
                                      errorWidget: (context, url, error) => new Icon(Icons.error),
                                      width: 60,height: 80,fit: BoxFit.cover,
                                    ),
                                  ),
                                  title: Text(data['name']),
                                  subtitle: Text((chatListSnapshot.hasData && chatListSnapshot.data.documents.length >0)
                                      ? chatListSnapshot.data.documents[0]['lastChat']
                                      : data['intro']),
                                  trailing: Padding(
                                      padding: const EdgeInsets.fromLTRB(0, 8, 4, 4),
                                      child: (chatListSnapshot.hasData && chatListSnapshot.data.documents.length > 0)
                                          ? StreamBuilder<QuerySnapshot>(
                                              stream: Firestore.instance
                                                  .collection('chatroom')
                                                  .document(chatListSnapshot.data.documents[0]['chatID'])
                                                  .collection(chatListSnapshot.data.documents[0]['chatID'])
                                                  .where('idTo',isEqualTo: widget.myID)
                                                  .where('isread', isEqualTo: false)
                                                  .snapshots(),
                                              builder: (context,notReadMSGSnapshot) {
                                                return Container(
                                                  width: 60,
                                                  height: 50,
                                                  child: Column(
                                                    children: <Widget>[
                                                      Text((chatListSnapshot.hasData && chatListSnapshot.data.documents.length >0)
                                                            ? readTimestamp(chatListSnapshot.data.documents[0]['timestamp'])
                                                            : '',style: TextStyle(fontSize: 12),
                                                      ),
                                                      Padding(
                                                          padding:const EdgeInsets.fromLTRB( 0, 5, 0, 0),
                                                          child: CircleAvatar(
                                                          radius: 9,
                                                          child: Text(
                                                            (chatListSnapshot.hasData && chatListSnapshot.data.documents.length > 0)
                                                                ? ((notReadMSGSnapshot.hasData && notReadMSGSnapshot.data.documents.length >0)
                                                                    ? '${notReadMSGSnapshot.data.documents.length}' : ''): '',
                                                            style: TextStyle(fontSize: 10),),
                                                          backgroundColor: (notReadMSGSnapshot.hasData && notReadMSGSnapshot.data.documents.length >0 &&
                                                                  notReadMSGSnapshot.hasData && notReadMSGSnapshot.data.documents.length >0)
                                                              ? Colors.red[400] : Colors.transparent,foregroundColor:Colors.white,
                                                        )),
                                                    ],
                                                  ),
                                                );
                                              })
                                          : Text('')),
                                          onTap: () {
                                            _moveTochatRoom(data['FCMToken'],data['userId'],data['name'],data['userImageUrl']);
                                          },
                          );
                        });
                  }
                }).toList())
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
      ));
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
