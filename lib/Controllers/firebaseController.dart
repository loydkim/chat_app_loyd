import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_core/firebase_core.dart' as firebase_core;
class FirebaseController {
  static FirebaseController get instanace => FirebaseController();

  // Save Image to Storage
  Future<String> saveUserImageToFirebaseStorage(userId,userName,userIntro,userImageFile) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId',userId);
      await prefs.setString('name',userName);
      await prefs.setString('intro',userIntro);

      String filePath = 'userImages/$userId';


      // final StorageReference storageReference = FirebaseStorage().ref().child(filePath);
      // final StorageUploadTask uploadTask = storageReference.putFile(userImageFile);

      try {
        await firebase_storage.FirebaseStorage.instance
            .ref(filePath)
            .putFile(userImageFile);
      } on firebase_core.FirebaseException catch (e) {
        print('upload image exception, code is ${e.code}');
        // e.g, e.code == 'canceled'
      }

      // StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
      // String imageURL = await storageTaskSnapshot.ref.getDownloadURL(); // Image URL from firebase's image file
      String imageURL = await firebase_storage.FirebaseStorage.instance
          .ref(filePath)
          .getDownloadURL();
      String result = await saveUserDataToFirebaseDatabase(userId,userName,userIntro,imageURL);

      return result;
    }catch(e) {
      print(e.message);
      return null;
    }
  }

  Future<String> sendImageToUserInChatRoom(croppedFile,chatID) async {
    try {
      String imageTimeStamp = DateTime.now().millisecondsSinceEpoch.toString();
      String filePath = 'chatrooms/$chatID/$imageTimeStamp';

      // final StorageReference storageReference = FirebaseStorage().ref().child(filePath);
      // final StorageUploadTask uploadTask = storageReference.putFile(croppedFile);
      // StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
      // String result = await storageTaskSnapshot.ref.getDownloadURL();

      try {
        await firebase_storage.FirebaseStorage.instance
            .ref(filePath)
            .putFile(croppedFile);
      } on firebase_core.FirebaseException catch (e) {
        print('upload image exception, code is ${e.code}');
        // e.g, e.code == 'canceled'
      }

      // String imageURL = await firebase_storage.FirebaseStorage.instance
      //     .ref(filePath)
      //     .getDownloadURL();

      return await firebase_storage.FirebaseStorage.instance
          .ref(filePath)
          .getDownloadURL();
    }catch(e) {
      print(e.message);
    }
  }

  // About Firebase Database
  Future<String> saveUserDataToFirebaseDatabase(userId,userName,userIntro,downloadUrl) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final QuerySnapshot result = await FirebaseFirestore.instance.collection('users').where('FCMToken', isEqualTo: prefs.get('FCMToken')).get();
      final List<DocumentSnapshot> documents = result.docs;
      String myID = userId;
      if (documents.length == 0) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'userId':userId,
          'name':userName,
          'intro':userIntro,
          'userImageUrl':downloadUrl,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'FCMToken':prefs.get('FCMToken')?? 'NOToken',
        });
      }else {
        String userID = documents[0]['userId'];
        myID = userID;
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId',myID);
        await FirebaseFirestore.instance.collection('users').doc(userID).update({
          'name':userName,
          'intro':userIntro,
          'userImageUrl':downloadUrl,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'FCMToken':prefs.get('FCMToken')?? 'NOToken',
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