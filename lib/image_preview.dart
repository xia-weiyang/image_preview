library image_preview;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_preview/image_gallery.dart';
import 'package:image_preview/image_page.dart';

void openImagePage(BuildContext context, String imgUrl) {
  Navigator.push(context,
      MaterialPageRoute<void>(builder: (BuildContext context) {
    return ImagePage(
      url: imgUrl,
      heroTag: imgUrl,
    );
  }));
}

void openImagesPage(BuildContext context, List<String> imgUrls, int index) {
  Navigator.push(context,
      MaterialPageRoute<void>(builder: (BuildContext context) {
    return ImageGalleryPage(
      imageUrls: imgUrls,
      initialIndex: index,
    );
  }));
}
