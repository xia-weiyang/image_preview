library image_preview;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_preview/image_gallery.dart';
import 'package:image_preview/image_view.dart';

void openImagePage(
  BuildContext context, {
  String imgUrl,
  OnLongPressHandler onLongPressHandler,
}) {
  Navigator.push(context,
      MaterialPageRoute<void>(builder: (BuildContext context) {
    return ImageGalleryPage(
      imageUrls: [imgUrl],
      onLongPressHandler: onLongPressHandler,
    );
  }));
}

void openImagesPage(
  BuildContext context, {
  @required List<String> imgUrls,
  int index = 0,
  OnLongPressHandler onLongPressHandler,
}) {
  Navigator.push(context,
      MaterialPageRoute<void>(builder: (BuildContext context) {
    return ImageGalleryPage(
      imageUrls: imgUrls,
      initialIndex: index,
      onLongPressHandler: onLongPressHandler,
    );
  }));
}
