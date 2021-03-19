
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ImageController {
  static ImageController get instance => ImageController();

  Future<File> cropImageFromFile() async{
    final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
    final File imageFileFromLibrary = File(pickedFile.path);

    // Start crop iamge then take the file.
    File croppedFile = await ImageCropper.cropImage(
        sourcePath: imageFileFromLibrary.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        iosUiSettings: IOSUiSettings(
          minimumAspectRatio: 1.0,
        )
    );
    return croppedFile != null ? croppedFile : null;
  }

  CachedNetworkImage cachedImage(String imageUrl){
    return CachedNetworkImage(
      imageUrl: imageUrl,//data['userImageUrl'],
      placeholder: (context, url) => Container(
        transform:
        Matrix4.translationValues(0, 0, 0),
        child: Container(width: 60,height: 80,
            child: Center(child:new CircularProgressIndicator())),),
      errorWidget: (context, url, error) => new Icon(Icons.error),
      width: 60,height: 80,fit: BoxFit.cover,
    );
  }
}