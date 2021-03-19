

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../common_widgets.dart';

Widget mineListTile(BuildContext context, String message, String time, bool isRead, String type) {
  final size = MediaQuery.of(context).size;
  return Padding( padding: const EdgeInsets.only(top:2.0,right: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Padding(
            padding: const EdgeInsets.only(bottom:14.0, right: 2,left:4),
            child:
            isRead ? Container(
              width: size.width*0.044,
              child: Stack(
                children: [
                  Positioned(
                      right:4,
                      child: FaIcon(FontAwesomeIcons.check,color: Colors.blue,size: 10,)
                  ),
                  FaIcon(FontAwesomeIcons.check,color: Colors.blue,size: 10,),

                ],
              ),
            ) :
            FaIcon(FontAwesomeIcons.check,color: Colors.grey,size: 10,)
          // Text(isRead ? '' : '1',style: TextStyle(fontSize: 12,color: Colors.yellow[900]),),

        ),
        Padding(
          padding: const EdgeInsets.only(bottom:14.0, right: 4,left:8),
          child: Text(time,style: TextStyle(fontSize: 12),),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(padding: const EdgeInsets.fromLTRB(0,2,4,4),
              child: Container(
                constraints: BoxConstraints(maxWidth: size.width - size.width*0.28),
                decoration: BoxDecoration(
                  color: type == 'text' ? Colors.green[700] : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Padding(
                  padding: EdgeInsets.all(type == 'text' ? 10.0:0),
                  child: Container(
                      child: type == 'text' ? Text(message,
                        style: TextStyle(color: Colors.white),) :
                      imageMessage(context,message)
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}