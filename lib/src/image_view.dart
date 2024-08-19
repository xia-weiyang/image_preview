import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_preview/preview_data.dart';
import 'package:image_preview/src/file_download.dart';
import 'package:photo_view/photo_view.dart';

typedef OnLongPressHandler(BuildContext context, PreviewData data);

class ImageView extends StatefulWidget {
  const ImageView({
    Key? key,
    required this.data,
    required this.heroTag,
    required this.open,
    this.scaleStateChangedCallback,
    this.onLongPressHandler,
    this.infoWidget,
  }) : super(key: key);

  @override
  _ImageViewState createState() => _ImageViewState();

  final ImageData data;

  final String heroTag;

  final bool open;

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
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    widgets.add(ImagePreview(
      data: widget.data,
      heroTag: widget.heroTag,
      open: widget.open,
      onLongPressHandler: widget.onLongPressHandler,
      scaleStateChangedCallback: widget.scaleStateChangedCallback,
    ));
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
}

class ImagePreview extends StatefulWidget {
  const ImagePreview({
    super.key,
    required this.data,
    required this.heroTag,
    required this.open,
    this.onLongPressHandler,
    this.scaleStateChangedCallback,
  });

  final ImageData data;
  final String heroTag;
  final bool open;
  final OnLongPressHandler? onLongPressHandler;
  final ValueChanged<PhotoViewScaleState>? scaleStateChangedCallback;

  @override
  State<StatefulWidget> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  FileDownloader? fileDownloader;
  Future<String>? downloadFuture;
  final delay = Future.delayed(Duration(milliseconds: 500));
  var open = false;
  ImageProvider? imageProvide;
  ImageProvider? imageProvideThumbnail;

  @override
  void initState() {
    open = widget.open;
    if (widget.data.url != null && widget.data.url!.isNotEmpty) {
      imageProvide = NetworkImage(widget.data.url!);
    }
    if (widget.data.thumbnailUrl != null &&
        widget.data.thumbnailUrl!.isNotEmpty) {
      imageProvideThumbnail = NetworkImage(widget.data.thumbnailUrl!);
    }
    super.initState();
  }

  @override
  void dispose() {
    fileDownloader?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ImagePreview oldWidget) {
    fileDownloader?.cancel();
    fileDownloader = null;
    downloadFuture = null;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    // 如果是web环境，直接加载网络图片
    if (kIsWeb) {
      return _buildWeb();
    }

    return _existFile()
        ? open
            ? FutureBuilder(
                future: delay,
                builder: (_, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return _buildImageWidgetPre();
                  }
                  return ImageLoading(
                    tag: widget.heroTag,
                    showLoading: false,
                    path: _existThumbnailFile()
                        ? widget.data.thumbnailPath
                        : null,
                  );
                },
              )
            : _buildImageWidgetPre()
        : FutureBuilder(
            future: getDownloadFuture(),
            builder: (_, snapshot) {
              if (snapshot.hasData) {
                if ('success' == snapshot.data) {
                  return _buildImageWidgetPre();
                } else {
                  return ImageError(
                    msg: '加载图片失败',
                    describe: '${widget.data.url}\n${snapshot.data}',
                  );
                }
              } else {
                return ImageLoading(
                  tag: widget.heroTag,
                  path:
                      _existThumbnailFile() ? widget.data.thumbnailPath : null,
                );
              }
            });
  }

  Widget _buildWeb() {
    if (widget.data.url == null || widget.data.url!.isEmpty) {
      return ImageError(
        msg: '加载图片失败',
        describe: '地址为空',
      );
    }
    return open
        ? FutureBuilder(
            future: delay,
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return _buildImageWidgetPreWeb();
              }
              return imageProvideThumbnail == null
                  ? SizedBox()
                  : Align(
                      alignment: Alignment.center,
                      child: Hero(
                        child: Container(
                          width: double.infinity,
                          child: Image(
                            image: imageProvideThumbnail!,
                            fit: BoxFit.contain,
                          ),
                        ),
                        tag: widget.heroTag,
                      ),
                    );
            },
          )
        : _buildImageWidgetPreWeb();
  }

  Widget _buildImageWidgetPreWeb() {
    return _buildImageWidget(
      imageProvide!,
      imageProvideThumbnail == null ? null : imageProvideThumbnail,
    );
  }

  Widget _buildImageWidgetPre() {
    return _buildImageWidget(
      FileImage(File.fromUri(Uri.file(widget.data.path!))),
      _existThumbnailFile()
          ? FileImage(File.fromUri(Uri.file(widget.data.thumbnailPath!)))
          : null,
    );
  }

  Widget _buildImageWidget(ImageProvider imageProvide,
      [ImageProvider? loadImageProvide]) {
    return GestureDetector(
      onLongPress: () {
        if (widget.onLongPressHandler != null) {
          widget.onLongPressHandler!(
              context,
              PreviewData(
                type: Type.image,
                image: widget.data,
              ));
        }
      },
      child: PhotoView(
        imageProvider: imageProvide,
        loadingBuilder: loadImageProvide == null
            ? null
            : (_, event) {
                return Center(
                  child: Container(
                    width: double.infinity,
                    child: Image(
                      image: loadImageProvide,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
        heroAttributes: PhotoViewHeroAttributes(tag: widget.heroTag),
        scaleStateChangedCallback: widget.scaleStateChangedCallback,
        minScale: PhotoViewComputedScale.contained * 1.0,
        maxScale: PhotoViewComputedScale.covered * 3.0,
        errorBuilder: (_, msg, stack) {
          print('PhotoView error: $msg \n $stack');
          return ImageError(
            msg: '加载图片失败',
            describe: '${widget.data.url}\n${msg}',
          );
        },
      ),
    );
  }

  /// 检查path是否存在缓存文件
  bool _existFile() {
    if (widget.data.path == null) return false;
    final file = File(widget.data.path!);
    bool result = file.existsSync();
    return result;
  }

  /// 检查缩略图是否存在缓存文件
  bool _existThumbnailFile() {
    if (widget.data.thumbnailPath == null) return false;
    final file = File(widget.data.thumbnailPath!);
    return file.existsSync();
  }

  Future<String> getDownloadFuture() {
    if (downloadFuture == null) {
      downloadFuture = _downloadFile();
    }
    return downloadFuture!;
  }

  Future<String> _downloadFile() async {
    if (widget.data.path == null || widget.data.path!.isEmpty)
      return "No download path specified.";
    if (widget.data.url == null || widget.data.url!.isEmpty)
      return "No download url specified.";
    fileDownloader ??= FileDownloader();
    return await fileDownloader!.download(widget.data.url!, widget.data.path!);
  }
}

class ImageLoading extends StatelessWidget {
  final String? path;
  final String tag;
  final bool showLoading;

  const ImageLoading({
    Key? key,
    this.path,
    this.showLoading = true,
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

    return path == null || path!.isEmpty
        ? widget
        : Builder(builder: (context) {
            final child = Align(
              alignment: Alignment.center,
              child: Hero(
                child: Container(
                  width: double.infinity,
                  child: Image(
                    image: FileImage(File.fromUri(Uri.file(path!))),
                    fit: BoxFit.contain,
                  ),
                ),
                tag: tag,
              ),
            );

            return showLoading
                ? Stack(
                    children: <Widget>[
                      child,
                      widget,
                    ],
                  )
                : child;
          });
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
