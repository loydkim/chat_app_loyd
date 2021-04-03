import 'package:chatapploydlab/subWidgets/common_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class FBAuth{
  static FBAuth get instanace => FBAuth();

  FirebaseAuth auth = FirebaseAuth.instance;

  Future<String> addUserUsingEmail(BuildContext context, String emailAddress) async{
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailAddress,
          password: "SuperSecretPassword!"
      );
      return userCredential.user.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
      showAlertDialog(context,e.code);
    } catch (e) {
      print(e);
    }
  }
}