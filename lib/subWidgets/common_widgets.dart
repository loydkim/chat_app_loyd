
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'full_photo.dart';

Widget loadingCircle(bool value,){
  return Positioned(
    child: value ? Container(
      child: Center(
        child: CircularProgressIndicator(),
      ),
      color: Colors.white.withOpacity(0.7),
    ) : Container(),
  );
}

Widget loadingCircleForFB(){
  return Container(
    child: Center(
      child: CircularProgressIndicator(),
    ),
    color: Colors.white.withOpacity(0.7),
  );
}

Widget imageMessage(context,imageUrlFromFB) {
  return Container(
    width: 160,
    height: 160,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10.0),
    ),
    child: GestureDetector(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => FullPhoto(url: imageUrlFromFB)));
      },
      child: CachedNetworkImage(
        imageUrl: imageUrlFromFB,
        placeholder: (context, url) => Container(
          transform: Matrix4.translationValues(0, 0, 0),
          child: Container( width: 60, height: 80,
              child: Center(child: new CircularProgressIndicator())),
        ),
        errorWidget: (context, url, error) => new Icon(Icons.error),
        width: 60,
        height: 80,
        fit: BoxFit.cover,
      ),
    ),
  );
}

void showAlertDialog(context,String msg) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: Text(msg),
      );
    });
}