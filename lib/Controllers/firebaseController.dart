import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseController {
  static FirebaseController get instanace => FirebaseController();

  Future<String> saveUserImageToFirebaseStorage(userId,userName,userIntro,userImageFile) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId',userId);
      await prefs.setString('name',userName);
      await prefs.setString('intro',userIntro);

      String filePath = 'userImages/$userId';
      final StorageReference storageReference = FirebaseStorage().ref().child(filePath);
      final StorageUploadTask uploadTask = storageReference.putFile(userImageFile);

      StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
      String imageURL = await storageTaskSnapshot.ref.getDownloadURL();
      String result = await saveUserDataToFirebaseDatabase(userId,userName,userIntro,imageURL);
      return result;
    }catch(e) {
      print(e.message);
      return null;
    }
  }

  Future<String> saveUserDataToFirebaseDatabase(userId,userName,userIntro,downloadUrl) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final QuerySnapshot result = await Firestore.instance.collection('users').where('FCMToken', isEqualTo: prefs.get('FCMToken')).getDocuments();
      final List<DocumentSnapshot> documents = result.documents;
      String myID = userId;
      if (documents.length == 0) {
        await Firestore.instance.collection('users').document(userId).setData({
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
        await Firestore.instance.collection('users').document(userID).updateData({
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

  Future<List<DocumentSnapshot>> takeUserInformationFromFBDB() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final QuerySnapshot result = await Firestore.instance.collection('users').where('FCMToken', isEqualTo: prefs.get('FCMToken')).getDocuments();
    return result.documents;
  }

  Future<void> getUnreadMSGCount() async{
    try {
      int unReadMSGCount = 0;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String myId = (prefs.get('userId') ?? 'NoId');

      if (myId != 'NoId') {
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
      }
      FlutterAppBadger.updateBadgeCount(unReadMSGCount);
    }catch(e) {
      print(e.message);
    }
  }
}