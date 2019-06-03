import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import 'image_view.dart';

class ImageGalleryPage extends StatefulWidget {
  ImageGalleryPage({
    Key key,
    this.initialIndex = 0,
    @required this.imageUrls,
    this.onLongPressHandler,
    this.heroTags,
  }) : super(key: key) {
    assert(initialIndex >= 0 && initialIndex < imageUrls.length);
    if (heroTags != null) assert(heroTags.length == imageUrls.length);
  }

  @override
  _ImageGalleryPageState createState() => _ImageGalleryPageState();

  final int initialIndex;

  final List<String> imageUrls;

  final List<String> heroTags;

  final OnLongPressHandler onLongPressHandler;
}

class _ImageGalleryPageState extends State<ImageGalleryPage> {
  PageController _controller;
  bool _locked;

  @override
  void initState() {
    _controller = PageController(initialPage: widget.initialIndex);
    _locked = false;
    super.initState();
  }

  void scaleStateChangedCallback(PhotoViewScaleState scaleState) {
    setState(() {
      _locked = (scaleState == PhotoViewScaleState.initial ||
              scaleState == PhotoViewScaleState.zoomedOut)
          ? false
          : true;
    });
  }

  int get actualPage {
    return _controller.hasClients ? _controller.page.floor() : 0;
  }

  int get itemCount {
    return widget.imageUrls.length;
  }

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
        child: PageView.builder(
          controller: _controller,
          itemCount: itemCount,
          itemBuilder: _buildItem,
          physics: _locked
              ? const NeverScrollableScrollPhysics()
              : ClampingScrollPhysics(),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    return ClipRect(
      child: ImageView(
        url: widget.imageUrls[index],
        heroTag: widget.heroTags != null
            ? widget.heroTags[index]
            : widget.imageUrls[index],
        scaleStateChangedCallback: scaleStateChangedCallback,
        onLongPressHandler: widget.onLongPressHandler,
      ),
    );
  }
}
