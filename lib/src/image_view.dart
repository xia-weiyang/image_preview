import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';

typedef OnLongPressHandler(BuildContext context, String ingUrl);

class ImageView extends StatefulWidget {
  const ImageView({
    Key? key,
    required this.url,
    this.originalUrl,
    required this.heroTag,
    this.scaleStateChangedCallback,
    this.onLongPressHandler,
    this.errorMsg,
    this.infoWidget,
  }) : super(key: key);

  @override
  _ImageViewState createState() => _ImageViewState();

  final String url;

  final String? originalUrl;

  final String heroTag;

  final String? errorMsg;

  final ValueChanged<PhotoViewScaleState>? scaleStateChangedCallback;

  final OnLongPressHandler? onLongPressHandler;

  /// 可用于描述图片
  final Widget? infoWidget;
}

class _ImageViewState extends State<ImageView> {
  var _currentHeight = 130.0;
  final _maxHeight = 130.0;
  final _minHeight = 20.0;

  @override
  Widget build(BuildContext context) {
    var imgUrl = widget.url;
    if (widget.originalUrl != null && widget.originalUrl!.isNotEmpty) {
      imgUrl = widget.originalUrl!;
    }
    final widgets = <Widget>[];
    widgets.add(widget.url.startsWith('http')
        ? CachedNetworkImage(
            imageUrl: imgUrl,
            fadeInDuration: Duration(milliseconds: 200),
            fadeOutDuration: Duration(milliseconds: 200),
            placeholderFadeInDuration: Duration(milliseconds: 200),
            placeholder: (context, str) => ImageLoading(
              url: widget.url == widget.originalUrl ? null : widget.url,
              tag: widget.heroTag,
            ),
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
        : _buildImageWidget(FileImage(File.fromUri(Uri.file(imgUrl)))));
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
      onLongPress: () {
        if (widget.onLongPressHandler != null) {
          widget.onLongPressHandler!(context, widget.originalUrl ?? widget.url);
        }
      },
      child: PhotoView(
        imageProvider: imageProvide,
        heroAttributes: PhotoViewHeroAttributes(tag: widget.heroTag),
        scaleStateChangedCallback: widget.scaleStateChangedCallback,
        minScale: PhotoViewComputedScale.contained * 1.0,
        maxScale: PhotoViewComputedScale.covered * 3.0,
      ),
    );
  }
}

class ImageLoading extends StatelessWidget {
  final String? url;
  final String tag;

  const ImageLoading({
    Key? key,
    this.url,
    required this.tag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final widget = Center(
        child: SizedBox(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
      ),
    ));

    return url == null
        ? widget
        : Stack(
            children: <Widget>[
              Center(
                child: Hero(
                  child: CachedNetworkImage(
                    imageUrl: url!,
                  ),
                  tag: tag,
                ),
              ),
              widget,
            ],
          );
  }
}

class ImageError extends StatelessWidget {
  final String? describe;
  final String? msg;

  const ImageError({
    Key? key,
    this.msg,
    this.describe,
  }) : super(key: key);

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
          msg ?? '图片加载失败',
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
