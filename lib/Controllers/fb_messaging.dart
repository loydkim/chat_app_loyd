import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:chatapploydlab/Model/const.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'fb_firestore.dart';

Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) {
  if (message.containsKey('data')) {
    print('myBackgroundMessageHandler data');
    final dynamic data = message['data'];
  }

  if (message.containsKey('notification')) {
    print('myBackgroundMessageHandler notification');
    final dynamic notification = message['notification'];
  }
  // Or do other work.
}

class NotificationController {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static NotificationController get instance => NotificationController();

//  NotificationController() {
//    takeFCMTokenWhenAppLaunch();
//    initLocalNotification();
//  }

  Future takeFCMTokenWhenAppLaunch() async {
    try{

      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('User granted provisional permission');
      } else {
        print('User declined or has not accepted permission');
      }


      SharedPreferences prefs = await SharedPreferences.getInstance();
      // String userToken = prefs.get('FCMToken');
      // if (userToken == null) {
      _firebaseMessaging.getToken(
        vapidKey: firebaseCloudvapidKey
      ).then((val) async {
        print('Token: '+val);
        prefs.setString('FCMToken', val);
        String userID = prefs.get('userId');
        if(userID != null) {
          FBCloudStore.instanace.updateUserToken(userID, val);
        }
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
        }

        RemoteNotification notification = message.notification;
        AndroidNotification android = message.notification?.android;

        final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'high_importance_channel', // id
          'High Importance Notifications', // title
          'This channel is used for important notifications.', // description
          importance: Importance.max,
        );

        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);

        if (notification != null && android != null) {
          //TODO: show snack bar or public UI here
          flutterLocalNotificationsPlugin.show(
              notification.hashCode,
              notification.title,
              notification.body,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  channel.id,
                  channel.name,
                  channel.description,
                  // TODO add a proper drawable resource to android, for now using
                  //      one that already exists in example app.
                  icon: android?.smallIcon,
                ),
              ));
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('A new onMessageOpenedApp event was published!');
        // Navigator.pushNamed(context, '/message',
        //     arguments: MessageArguments(message, true));
      });

      // }

      // _firebaseMessaging.configure(
      //   onMessage: (Map<String, dynamic> message) async {
      //     print("onMessage: $message");
      //     String msg = 'notibody';
      //     String name = 'chatapp';
      //     if (Platform.isIOS) {
      //       msg = message['aps']['alert']['body'];
      //       name = message['aps']['alert']['title'];
      //     }else {
      //       msg = message['notification']['body'];
      //       name = message['notification']['title'];
      //     }
      //
      //     String currentChatRoom = (prefs.get('currentChatRoom') ?? 'None');
      //
      //     if(Platform.isIOS) {
      //       if(message['chatroomid'] != currentChatRoom) {
      //         sendLocalNotification(name,msg);
      //       }
      //     }else {
      //       if(message['data']['chatroomid'] != currentChatRoom) {
      //         sendLocalNotification(name,msg);
      //       }
      //     }
      //
      //     FirebaseController.instanace.getUnreadMSGCount();
      //   },
      //   onBackgroundMessage: Platform.isIOS ? null : myBackgroundMessageHandler,
      //   onLaunch: (Map<String, dynamic> message) async {
      //     print("onLaunch: $message");
      //   },
      //   onResume: (Map<String, dynamic> message) async {
      //     print("onResume: $message");
      //   },
      // );

    }catch(e) {
      print(e.message);
    }
  }

  Future initLocalNotification() async{
    if (Platform.isIOS ) {
      // set iOS Local notification.
      var initializationSettingsAndroid =
      AndroidInitializationSettings('icon_notification');
      var initializationSettingsIOS = IOSInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
        onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
      );
      var initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
      await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
          onSelectNotification: _selectNotification);
    }else {// set Android Local notification.
      var initializationSettingsAndroid = AndroidInitializationSettings('icon_notification');
      var initializationSettingsIOS = IOSInitializationSettings(
          onDidReceiveLocalNotification: _onDidReceiveLocalNotification);
      var initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
      await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
          onSelectNotification: _selectNotification);
    }
  }

  Future _onDidReceiveLocalNotification(int id, String title, String body, String payload) async { }

  Future _selectNotification(String payload) async { }

  sendLocalNotification(name,msg) async{
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.max, priority: Priority.high, ticker: 'ticker');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        android:androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);
    await _flutterLocalNotificationsPlugin.show(
        0, name, msg, platformChannelSpecifics,
        payload: 'item x');
  }

  // Send a notification message

  Future<void> sendNotificationMessageToPeerUser(unReadMSGCount,messageType,textFromTextField,myName,chatID,peerUserToken,myImageUrl) async {
    // FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
    try{
      await http.post(
        // 'https://fcm.googleapis.com/fcm/send',
        // 'https://api.rnfirebase.io/messaging/send',
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'key=$firebaseCloudserverToken',
        },
        body: jsonEncode(
          <String, dynamic>{
            'token': peerUserToken,
            'notification': <String, dynamic>{
              'body': messageType == 'text' ? '$textFromTextField' : '(Photo)',
              'title': '$myName',
              'badge':'$unReadMSGCount',//'$unReadMSGCount'
              "sound" : "default",
              "image" : myImageUrl
            },
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'id': '1',
              'status': 'done',
              'chatroomid': chatID,
            },
            'to': peerUserToken,
          },
        ),
      );
    } catch (e) {
      print(e);
    }

  }

  // String constructFCMPayload(String token) {
  //   return jsonEncode({
  //     'token': token,
  //     'data': {
  //       'via': 'FlutterFire Cloud Messaging!!!',
  //       'count': 0,
  //     },
  //     'notification': {
  //       'title': 'Hello FlutterFire!',
  //       'body': 'This notification (#$_messageCount) was created via FCM!',
  //     },
  //   });
  // }
}