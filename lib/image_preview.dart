library image_preview;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_preview/image_gallery.dart';
import 'package:image_preview/image_view.dart';

/// 打开单张图片
void openImagePage(
  BuildContext context, {
  String imgUrl,
  String heroTag,
  String errorMsg,
  OnLongPressHandler onLongPressHandler,
}) {
  Navigator.push(context,
      MaterialPageRoute<void>(builder: (BuildContext context) {
    return ImageGalleryPage(
      imageUrls: [imgUrl],
      heroTags: [heroTag],
      errorMsg: errorMsg,
      onLongPressHandler: onLongPressHandler,
    );
  }));
}

/// 打开多张图片
/// [errorMsg] 当图片加载错误时的描述信息
void openImagesPage(
  BuildContext context, {
  @required List<String> imgUrls,
  List<String> heroTags,
  int index = 0,
  String errorMsg,
  OnLongPressHandler onLongPressHandler,
}) {
  Navigator.push(context,
      MaterialPageRoute<void>(builder: (BuildContext context) {
    return ImageGalleryPage(
      imageUrls: imgUrls,
      heroTags: heroTags,
      errorMsg: errorMsg,
      initialIndex: index,
      onLongPressHandler: onLongPressHandler,
    );
  }));
}
