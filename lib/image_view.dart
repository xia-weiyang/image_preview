import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';

typedef OnLongPressHandler(BuildContext context, String ingUrl);

class ImageView extends StatefulWidget {
  const ImageView({
    Key key,
    @required this.url,
    this.heroTag,
    this.scaleStateChangedCallback,
    this.onLongPressHandler,
    this.errorMsg,
    this.infoWidget,
  }) : super(key: key);

  @override
  _ImageViewState createState() => _ImageViewState();

  final String url;

  final String heroTag;

  final String errorMsg;

  final PhotoViewScaleStateChangedCallback scaleStateChangedCallback;

  final OnLongPressHandler onLongPressHandler;

  /// 可用于描述图片
  final Widget infoWidget;
}

class _ImageViewState extends State<ImageView> {
  var _currentHeight = 130.0;
  final _maxHeight = 130.0;
  final _minHeight = 20.0;

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    widgets.add(widget.url.startsWith('http')
        ? CachedNetworkImage(
            imageUrl: widget.url,
            placeholder: (context, str) => ImageLoading(),
            errorWidget: (context, str, e) {
              return ImageError(
                msg: widget.errorMsg,
                describe: '$str \n $e',
              );
            },
            imageBuilder: (context, provider) {
              return _buildImageWidget(provider);
            },
          )
        : _buildImageWidget(FileImage(File.fromUri(Uri.file(widget.url)))));
    if (widget.infoWidget != null) {
      widgets.add(Align(
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          child: Container(
              height: _currentHeight,
              width: MediaQuery.of(context).size.width,
              color: const Color(0x44000000),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: widget.infoWidget,
              )),
          onVerticalDragUpdate: _handleDrag,
        ),
      ));
    }

    return Stack(children: widgets);
  }

  /// 处理拖拽
  void _handleDrag(DragUpdateDetails details) {
    // debugPrint(details.toString());
    var temp = _currentHeight;

    /// 向下滑动
    if (details.delta.dy > 0 && _currentHeight > _minHeight) {
      final y = _currentHeight - details.delta.dy;
      temp = y <= _minHeight ? _minHeight : y;
    }

    /// 向上滑动
    if (details.delta.dy < 0 && _currentHeight < _maxHeight) {
      final y = _currentHeight - details.delta.dy;
      temp = y >= _maxHeight ? _maxHeight : y;
    }

    // debugPrint(temp.toString());
    setState(() => _currentHeight = temp);
  }

  Widget _buildImageWidget(ImageProvider imageProvide) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      onLongPress: () {
        if (widget.onLongPressHandler != null)
          widget.onLongPressHandler(context, widget.url);
      },
      child: PhotoView(
        imageProvider: imageProvide,
        heroTag: widget.heroTag,
        loadingChild: ImageLoading(),
        scaleStateChangedCallback: widget.scaleStateChangedCallback,
        minScale: PhotoViewComputedScale.contained * 1.0,
        maxScale: PhotoViewComputedScale.covered * 3.0,
      ),
    );
  }
}

class ImageLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: SizedBox(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
      ),
    ));
  }
}

class ImageError extends StatelessWidget {
  final String describe;
  final String msg;

  const ImageError({
    Key key,
    this.msg = '图片加载失败',
    this.describe,
  })  : assert(msg != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          Icons.broken_image,
          color: Colors.red,
          size: 30,
        ),
        SizedBox(height: 10),
        Text(
          msg,
          style: TextStyle(color: Colors.red),
        ),
        SizedBox(height: 15),
        Container(
          width: MediaQuery.of(context).size.width - 100,
          child: Text(
            describe ?? '',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    ));
  }
}
