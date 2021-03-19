import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FBCloudStore {
  static FBCloudStore get instanace => FBCloudStore();

  // About Firebase Database
  Future<String> saveUserDataToFirebaseDatabase(userId,userName,userIntro,downloadUrl) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final QuerySnapshot result = await FirebaseFirestore.instance.collection('users').where('FCMToken', isEqualTo: prefs.get('FCMToken')).get();
      final List<DocumentSnapshot> documents = result.docs;
      String myID = userId;
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
      if (documents.length == 0) {
        FirebaseFirestore.instance.runTransaction((Transaction myTransaction) async {
          myTransaction.set(userDoc, {
            'name':userName,
            'intro':userIntro,
            'userImageUrl':downloadUrl,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
            'FCMToken':prefs.get('FCMToken')?? 'NOToken',
          });
        });
      }else {
        String userID = documents[0]['userId'];
        myID = userID;
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId',myID);

        FirebaseFirestore.instance.runTransaction((Transaction myTransaction) async {
          myTransaction.update(userDoc, {
            'name':userName,
            'intro':userIntro,
            'userImageUrl':downloadUrl,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
            'FCMToken':prefs.get('FCMToken')?? 'NOToken',
          });
        });
      }
      return myID;
    }catch(e) {
      print(e.message);
      return null;
    }
  }

  Future<void> updateUserToken(userID, token) async {
    await FirebaseFirestore.instance.collection('users').doc(userID).update({
      'FCMToken':token,
    });
  }

  Future<List<DocumentSnapshot>> takeUserInformationFromFBDB() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final QuerySnapshot result =
    await FirebaseFirestore.instance.
      collection('users').
      where('FCMToken', isEqualTo: prefs.get('FCMToken') ?? 'None').
      get();
    return result.docs;
  }

  Future<int> getUnreadMSGCount([String peerUserID]) async{
    try {
      int unReadMSGCount = 0;
      String targetID = '';
      SharedPreferences prefs = await SharedPreferences.getInstance();

      peerUserID == null ? targetID = (prefs.get('userId') ?? 'NoId') : targetID = peerUserID;
//      if (targetID != 'NoId') {
        final QuerySnapshot chatListResult =
        await FirebaseFirestore.instance.collection('users').doc(targetID).collection('chatlist').get();
        final List<DocumentSnapshot> chatListDocuments = chatListResult.docs;
        for(var data in chatListDocuments) {
          final QuerySnapshot unReadMSGDocument = await FirebaseFirestore.instance.collection('chatroom').
          doc(data['chatID']).
          collection(data['chatID']).
          where('idTo', isEqualTo: targetID).
          where('isread', isEqualTo: false).
          get();

          final List<DocumentSnapshot> unReadMSGDocuments = unReadMSGDocument.docs;
          unReadMSGCount = unReadMSGCount + unReadMSGDocuments.length;
        }
        print('unread MSG count is $unReadMSGCount');
//      }
      if (peerUserID == null) {
        FlutterAppBadger.updateBadgeCount(unReadMSGCount);
        return null;
      }else {
        return unReadMSGCount;
      }

    }catch(e) {
      print(e.message);
    }
  }

  Future updateChatRequestField(String documentID,String lastMessage,chatID,myID,selectedUserID) async{
    await FirebaseFirestore.instance
        .collection('users')
        .doc(documentID)
        .collection('chatlist')
        .doc(chatID)
        .set({'chatID':chatID,
      'chatWith':documentID == myID ? selectedUserID : myID,
      'lastChat':lastMessage,
      'timestamp':DateTime.now().millisecondsSinceEpoch});
  }

  Future sendMessageToChatRoom(chatID,myID,selectedUserID,content,messageType) async {
    await FirebaseFirestore.instance
        .collection('chatroom')
        .doc(chatID)
        .collection(chatID)
        .doc(DateTime.now().millisecondsSinceEpoch.toString()).set({
      'idFrom': myID,
      'idTo': selectedUserID,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'content': content,
      'type':messageType,
      'isread':false,
    });
  }
}