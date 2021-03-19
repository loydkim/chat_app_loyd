import 'package:chatapploydlab/Controllers/utils.dart';
import 'package:chatapploydlab/Model/const.dart';
import 'package:flutter/material.dart';

Widget youtubePromotion(){
  return Column(
    children: [
      _youtubeTitle(),
      _youtubeLinkTitle(),
      _youtubeLinkAddress(),
      _youtubeImage()
    ],
  );
}

Widget _youtubeTitle() {
  return Padding(
    padding: const EdgeInsets.only(left: 18.0, top: 10),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Loyd Lab (Youtube)',
        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
      ),
    ),
  );
}

Widget _youtubeLinkTitle() {
  return Padding(
    padding: const EdgeInsets.only(left: 20.0, top: 10),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Youtube link: ',
        style: TextStyle(fontSize: 16),
      ),
    ),
  );
}

Widget _youtubeLinkAddress() {
  return Padding(
    padding: const EdgeInsets.only(left: 20.0, top: 10),
    child: Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          launchURL();
        },
        child: Text(
          youtubeChannelLink,
          style: TextStyle(
            fontSize: 14,
            color: Colors.blue[700],
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    ),
  );
}

Widget _youtubeImage() {
  return Expanded(child: Image.asset('images/youtube_screenshot.png'));
}