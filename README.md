<a href="https://www.buymeacoffee.com/loydkim" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 14px !important;width: 40px !important;" ></a>

# Chatapploydlab

| iOS Device  | Android Device |
| ------------- | ------------- |
| <img src="https://github.com/loydkim/chat_app_loyd/blob/master/ios_promotion.gif" width="300" height="560">  | <img src="https://github.com/loydkim/chat_app_loyd/blob/master/android_promotion.gif" width="340" height="560">  |

** Please click the Image to know how it works **

[![Youtube](https://img.youtube.com/vi/OnIRKAbOcq4/0.jpg)](https://youtu.be/OnIRKAbOcq4)

** To use it, you have to change your permission in the Database and Storage of the firebase. Because the project didn't consider authentication.

Go to Firebase Console - Database - Rule. Change it this ( )

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write
    }
  }
}

And change the permission in Storage

Go to Firebase Console - Storage - Rules.

rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write;
    }
  }
}


* Main features *

- Realtime chatting ( Don't need a refresh)
- Push Notification ( Background, Foreground)
- Badge count ( Show unread message count)
- Send an image ( Crop image and it can expand the image)

 The chat function is used in many apps. Flutter allows you to create iPhone and Android apps simultaneously. The main functions are push notification (background, foreground), Badge count, send an image, chat realtime. If you have any problems with my code or have any ideas to update, please leave a comment.

* Develop environment.

- Flutter SDK Version: 1.12.13+hotfix.9
- Flutter: 45.1.1
- Dart: 192.7761
- Xcode Version: 11.4.1
- Android Studio: 3.6.2
- OS Version: MacOS Catalina 10.15.4

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
