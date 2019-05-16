import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'image_view.dart';

class ImagePage extends StatefulWidget {
  const ImagePage({
    Key key,
    @required this.url,
    this.heroTag,
  }) : super(key: key);

  @override
  _ImagePageState createState() => _ImagePageState();

  final String url;

  final String heroTag;
}

class _ImagePageState extends State<ImagePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        constraints: BoxConstraints.expand(
          height: MediaQuery.of(context).size.height,
        ),
        child: ImageView(
          url: widget.url,
          heroTag: widget.heroTag,
        ),
      ),
    );
  }
}
