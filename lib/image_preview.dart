library image_preview;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
