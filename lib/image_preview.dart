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
  OnPageChanged onPageChanged,
}) {
  Navigator.push(context,
      MaterialPageRoute<void>(builder: (BuildContext context) {
    return ImageGalleryPage(
      imageUrls: [imgUrl],
      heroTags: [heroTag],
      errorMsg: errorMsg,
      onLongPressHandler: onLongPressHandler,
      onPageChanged: onPageChanged,
    );
  }));
}

/// 打开多张图片
/// [errorMsg] 当图片加载错误时的描述信息
/// [onPageChanged] 切换图片时调用，第一次打开时也会被调用
/// 返回的[Widget]可用于展示图片描述信息，如不需要可返回null
void openImagesPage(
  BuildContext context, {
  @required List<String> imgUrls,
  List<String> heroTags,
  int index = 0,
  String errorMsg,
  OnLongPressHandler onLongPressHandler,
  OnPageChanged onPageChanged,
}) {
  Navigator.push(context,
      MaterialPageRoute<void>(builder: (BuildContext context) {
    return ImageGalleryPage(
      imageUrls: imgUrls,
      heroTags: heroTags,
      errorMsg: errorMsg,
      initialIndex: index,
      onLongPressHandler: onLongPressHandler,
      onPageChanged: onPageChanged,
    );
  }));
}
