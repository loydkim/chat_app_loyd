If my code is helpful to you, I really appreceiate if you buy me a coffee 🙇🏻‍♂️☕️

[![](https://1.bp.blogspot.com/-dvUCBQdmi0s/YFfLITMCaiI/AAAAAAAABZE/Ej-_5PgqW14KKLYWVJg1SzlRup4Rvf_fQCLcBGAsYHQ/s0/68747470733a2f2f7777772e6275796d6561636f666665652e636f6d2f6173736574732f696d672f637573746f6d5f696d616765732f6f72616e67655f696d672e706e67.png)](https://www.buymeacoffee.com/loydkim)

# Chat app loyd lab

| iOS Device  | Android Device |
| ------------- | ------------- |
| ![](https://github.com/loydkim/chat_app_loyd/blob/master/Chat_App_iOS.gif)  | ![](https://github.com/loydkim/chat_app_loyd/blob/master/Chat_App_Android.gif) |

** To use it, you have to change your permission in the Database and Storage of the firebase.

Go to Firebase Console - Database - Rule. Change it this

```python
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```



And change the permission in Storage

Go to Firebase Console - Storage - Rules.

```python
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}

```

And To use notification, Please copy your firebase project server String to Model/const.dart file

Go to Firebase Console - Project settings - Cloud Messaging - Server key.

```python
const String firebaseCloudserverToken = 'YOUR_FB_SERVER_KEY';//AAAAFxtLywg:APA91bFbcXfhUI2b2MagqgYnL
const String firebaseCloudvapidKey = 'YOUR_VAPID_KEY';
const String youtubeChannelLink = 'https://www.youtube.com/channel/UCLNCErWFQ6LZoaV_JKOq_lQ';

const chatInstruction = """Chat App is committed to maintaining a healthy chat, and blocks users who disseminated vegan chats or photos.
We do not provide any other services other than this application. Beware of scam or illegal website promotion.
Attempts to send obscene, offensive, racist messages or request money transactions can result in permanent suspension and criminal prosecution.""";


```


* Main features *

- Realtime chatting with chat date ( Don't need a refresh )
- Push Notification with Image( Background, Foreground )
- Check is Read Message
- Custom Local Notification design
- Badge count ( Show unread message count)
- Send an image and edit ( Crop image and it can expand the image)

 The chat function is used in many apps. Flutter allows you to create iPhone and Android apps simultaneously. The main functions are push notification (background, foreground), Badge count, send an image, chat realtime. If you have any problems with my code or have any ideas to update, please leave a comment.

* Develop environment.

- Flutter SDK Version: 2.0.1
- Dart: 2.12.0
- Xcode Version: 12.4
- Android Studio: 4.1
- OS Version: MacOS Big Sur 11.2.3

Thank you for watching :)

#Flutter, #MobileApp, #Chatapp

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
