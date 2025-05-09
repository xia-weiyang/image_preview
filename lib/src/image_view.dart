import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_preview/preview_data.dart';
import 'package:image_preview/src/file_download.dart';
import 'package:image_preview/src/preview_gallery.dart';
import 'package:photo_view/photo_view.dart';

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
  String? _targetPath;

  @override
  void initState() {
    open = widget.open;
    _targetPath = widget.data.path;
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
    if (widget.data.url != oldWidget.data.url ||
        widget.data.asyncPath != widget.data.asyncPath ||
        widget.data.path != oldWidget.data.path) {
      _targetPath = widget.data.path;
      fileDownloader?.cancel();
      fileDownloader = null;
      downloadFuture = null;
    }
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
                    provider: widget.data.thumbnailProvide,
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
                  provider: widget.data.thumbnailProvide,
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
    Widget? image = null;
    if (widget.data.thumbnailProvide != null) {
      image = Image(image: widget.data.thumbnailProvide!, fit: BoxFit.contain);
    } else if (imageProvideThumbnail != null) {
      image = Image(
        image: imageProvideThumbnail!,
        fit: BoxFit.contain,
      );
    }

    return _buildImageWidget(imageProvide!, image);
  }

  Widget _buildImageWidgetPre() {
    Widget? image = null;
    if (widget.data.thumbnailProvide != null) {
      image = Image(image: widget.data.thumbnailProvide!, fit: BoxFit.contain);
    } else if (_existThumbnailFile()) {
      image = Image(
        image: FileImage(File.fromUri(Uri.file(widget.data.thumbnailPath!))),
        fit: BoxFit.contain,
      );
    }
    return _buildImageWidget(
      FileImage(File.fromUri(Uri.file(_targetPath ?? ''))),
      image,
    );
  }

  Widget _buildImageWidget(ImageProvider imageProvide, [Widget? loadImage]) {
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
        loadingBuilder: loadImage == null
            ? (_, event) {
                return ImageLoading();
              }
            : (_, event) {
                return Center(
                  child: Container(
                    width: double.infinity,
                    child: loadImage,
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
    if (_targetPath == null) return false;
    final file = File(_targetPath!);
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
    if (widget.data.asyncPath != null) {
      if (open) await Future.delayed(Duration(milliseconds: 500));
      _targetPath = await widget.data.asyncPath!();
      return 'success';
    }
    if (_targetPath == null || _targetPath!.isEmpty)
      return "No download path specified.";
    if (widget.data.url == null || widget.data.url!.isEmpty)
      return "No download url specified.";
    fileDownloader ??= FileDownloader();
    return await fileDownloader!.download(widget.data.url!, _targetPath!);
  }
}

class ImageLoading extends StatelessWidget {
  final String? path;
  final ImageProvider? provider;
  final String? tag;
  final bool showLoading;

  const ImageLoading({
    Key? key,
    this.path,
    this.provider,
    this.showLoading = true,
    this.tag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final widget = Center(
        child: SizedBox(
      child: Platform.isIOS || Platform.isMacOS
          ? const CupertinoActivityIndicator()
          : const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
            ),
    ));

    Widget? image = null;
    if (provider != null) {
      image = Image(image: provider!, fit: BoxFit.contain);
    } else if (path != null || path!.isNotEmpty) {
      image = Image(
        image: FileImage(File.fromUri(Uri.file(path!))),
        fit: BoxFit.contain,
      );
    }

    return image == null
        ? widget
        : Builder(builder: (context) {
            final child = Align(
              alignment: Alignment.center,
              child: Hero(
                child: Container(
                  width: double.infinity,
                  child: image,
                ),
                tag: tag ?? "",
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
