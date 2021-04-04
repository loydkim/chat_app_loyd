import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalNotificationData{
  final String userImage;
  final String userName;
  final String userMessage;

  LocalNotificationData({this.userImage, this.userName, this.userMessage});
}

class LocalNotificationView{

  final timeout = Duration(seconds: 4);
  final ms = Duration(milliseconds: 1);

  bool isShowLocalNotification = false;
  double localNotificationAnimationOpacity = 0.0;
  ValueChanged<List<dynamic>> changeNotificationState;
  LocalNotificationData localNotificationData = LocalNotificationData(
    userImage : "",
    userName: "User Name",
    userMessage: "User Message",
  );

  void checkLocalNotification(Function changeNotificationState,String chatID){
    this.changeNotificationState = changeNotificationState;
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('ChatList Got a message whilst in the foreground!');
      print('ChatList Message data: ${message.data}');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final inRoomChatId = prefs.getString("inRoomChatId") ?? "";

      if(inRoomChatId != message.data["chatroomid"]){
        if (message.data != null){// && chatID != message.data["chatroomid"]) {
          LocalNotificationData localData = LocalNotificationData(
            userImage : message.data["userImage"],
            userName: message.data["userName"],
            userMessage:message.data["message"],
          );
          this.changeNotificationState([localData,1.0]);
          startTimeout();
        }
      }


      // RemoteNotification notification = message.notification;
      // AndroidNotification android = message.notification?.android;
      // final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      // FlutterLocalNotificationsPlugin();
      // const AndroidNotificationChannel channel = AndroidNotificationChannel(
      //   'high_importance_channel', // id
      //   'High Importance Notifications', // title
      //   'This channel is used for important notifications.', // description
      //   importance: Importance.max,
      // );
      // await flutterLocalNotificationsPlugin
      //     .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      //     ?.createNotificationChannel(channel);
      // if (notification != null && android != null) {
      //   flutterLocalNotificationsPlugin.show(
      //       notification.hashCode,
      //       notification.title,
      //       notification.body,
      //       NotificationDetails(
      //         android: AndroidNotificationDetails(
      //           channel.id,
      //           channel.name,
      //           channel.description,
      //           icon: android?.smallIcon,
      //         ),
      //       ));
      // }
    });
  }

  Widget localNotificationCard(Size size){
    return Positioned(
        top:size.height/10,
        left:size.width/6,
        child: AnimatedOpacity(
          opacity: localNotificationAnimationOpacity,
          duration: Duration(milliseconds: 1000),
          child:
          localNotificationAnimationOpacity == 0 ? Container() : Container(
            width: size.width / 1.5,
            child: Card(
                color: Colors.red[900],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          width: 50,
                          height: 50,
                          child:
                          localNotificationData.userImage != "" ?
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24.0),
                            child:
                            CachedNetworkImage(
                              imageUrl: localNotificationData.userImage,
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
                          ) : Icon(Icons.account_circle,color: Colors.white,),

                        ),
                      ),
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom:4.0),
                            child: Text(localNotificationData.userName,style: TextStyle(color:Colors.white,fontSize: 16,fontWeight: FontWeight.bold),),
                          ),
                          Text(localNotificationData.userMessage,style: TextStyle(color:Colors.white,fontSize: 14)),
                        ],
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                      ),
                    ],
                  ),
                )
            ),
          ),
        )
    );
  }

  Timer startTimeout([int milliseconds]) {
    var duration = milliseconds == null ? timeout : ms * milliseconds;
    return Timer(duration, handleTimeout);
  }

  void handleTimeout() {
    this.changeNotificationState([null,0.0]);
  }
}