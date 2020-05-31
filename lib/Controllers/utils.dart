import 'dart:math';

import 'package:chatapploydlab/Model/const.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// For Chatlist Functions

String readTimestamp(int timestamp) {
  var now = DateTime.now();
  var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  var diff = now.difference(date);
  var time = '';

  if (diff.inSeconds <= 0 || diff.inSeconds > 0 && diff.inMinutes == 0 || diff.inMinutes > 0 && diff.inHours == 0 || diff.inHours > 0 && diff.inDays == 0) {
    if (diff.inHours > 0) {
      time = diff.inHours.toString() + 'h ago';
    }else if (diff.inMinutes > 0) {
      time = diff.inMinutes.toString() + 'm ago';
    }else if (diff.inSeconds > 0) {
      time = 'now';
    }else if (diff.inMilliseconds > 0) {
      time = 'now';
    }else if (diff.inMicroseconds > 0) {
      time = 'now';
    }else {
      time = 'now';
    }
  } else if (diff.inDays > 0 && diff.inDays < 7) {
    if (diff.inDays == 1) {
      time = diff.inDays.toString() + 'd ago';
    }
  } else if (diff.inDays > 6){
    if (diff.inDays == 7) {
      time = (diff.inDays / 7).floor().toString() + 'w ago';
    }
  }else if (diff.inDays > 29) {
    if (diff.inDays == 30) {
      time = (diff.inDays / 30).floor().toString() + 'm ago';
    }
  }
  return time;
}

String makeChatId(myID,selectedUserID) {
  String chatID;
  if (myID.hashCode > selectedUserID.hashCode) {
    chatID = '$selectedUserID-$myID';
  }else {
    chatID = '$myID-$selectedUserID';
  }
  return chatID;
}

int countChatListUsers(myID,snapshot) {
  int resultInt = snapshot.data.documents.length;
  for (var data in snapshot.data.documents) {
    if (data['userId'] == myID) {
      resultInt--;
    }
  }
  return resultInt;
}

// For ChatRoom Functions

String returnTimeStamp(int messageTimeStamp) {
  String resultString = '';
  var format = DateFormat('hh:mm a');
  var date = DateTime.fromMillisecondsSinceEpoch(messageTimeStamp);
  resultString = format.format(date);
  return resultString;
}

// For main view Functions

launchURL() async {
  const url = youtubeChannelLink;
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

String checkValidUserData(userImageFile,userImageUrlFromFB,name,intro) {
  String returnString = '';
  if(userImageFile.path == '' && userImageUrlFromFB == '') {
    returnString = returnString + 'Please select a image.';
  }

  if(name.trim() == '') {
    if(returnString.trim() != '') {
      returnString = returnString + '\n\n';
    }
    returnString = returnString + 'Please type your name';
  }

  if(intro.trim() == '') {
    if(returnString.trim() != '') {
      returnString = returnString + '\n\n';
    }
    returnString = returnString + 'Please type your intro';
  }
  return returnString;
}

String randomIdWithName(userName){
  int randomNumber = Random().nextInt(100000);
  return '$userName$randomNumber';
}