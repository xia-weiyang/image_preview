library image_preview;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_preview/image_gallery.dart';
import 'package:image_preview/image_view.dart';

void openImagePage(
  BuildContext context, {
  String imgUrl,
  String heroTag,
  OnLongPressHandler onLongPressHandler,
}) {
  Navigator.push(context,
      MaterialPageRoute<void>(builder: (BuildContext context) {
    return ImageGalleryPage(
      imageUrls: [imgUrl],
      heroTags: [heroTag],
      onLongPressHandler: onLongPressHandler,
    );
  }));
}

void openImagesPage(
  BuildContext context, {
  @required List<String> imgUrls,
  List<String> heroTags,
  int index = 0,
  OnLongPressHandler onLongPressHandler,
}) {
  Navigator.push(context,
      MaterialPageRoute<void>(builder: (BuildContext context) {
    return ImageGalleryPage(
      imageUrls: imgUrls,
      heroTags: heroTags,
      initialIndex: index,
      onLongPressHandler: onLongPressHandler,
    );
  }));
}
