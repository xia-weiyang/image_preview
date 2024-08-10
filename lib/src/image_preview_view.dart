import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_preview/preview_data.dart';
import 'package:image_preview/src/file_download.dart';

class ImagePreviewThumbnailView extends StatefulWidget {
  const ImagePreviewThumbnailView({
    super.key,
    required this.data,
    required this.fit,
  });

  final ImageData data;
  final BoxFit fit;

  @override
  State<StatefulWidget> createState() => _ImagePreviewThumbnailViewState();
}

class _ImagePreviewThumbnailViewState extends State<ImagePreviewThumbnailView> {
  FileDownloader? fileDownloader;
  Future<String>? downloadFuture;

  @override
  void dispose() {
    fileDownloader?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      if (widget.data.thumbnailUrl == null ||
          widget.data.thumbnailUrl!.isEmpty) {
        return buildError();
      }
      return buildPlaceholder(
        child: Image(
          image: NetworkImage(widget.data.thumbnailUrl ?? ''),
          errorBuilder: (con, error, stack) {
            return buildError();
          },
          fit: widget.fit,
        ),
      );
    }

    return _existFile()
        ? Image(
            image:
                FileImage(File.fromUri(Uri.file(widget.data.thumbnailPath!))),
            fit: widget.fit,
          )
        : FutureBuilder(
            future: getDownloadFuture(),
            builder: (_, snapshot) {
              if (snapshot.hasData) {
                if ('success' == snapshot.data) {
                  return Image(
                    image: FileImage(
                        File.fromUri(Uri.file(widget.data.thumbnailPath!))),
                    fit: widget.fit,
                  );
                } else {
                  return buildError();
                }
              }
              return buildPlaceholder();
            });
  }

  /// 检查是否存在缓存文件
  bool _existFile() {
    if (widget.data.thumbnailPath == null) return false;
    final file = File(widget.data.thumbnailPath!);
    bool result = file.existsSync();
    return result;
  }

  Widget buildPlaceholder({Widget? child}) {
    return LayoutBuilder(builder: (context, cons) {
      return Container(
        width: cons.maxWidth == double.infinity ? 200 : cons.maxWidth,
        height: cons.maxHeight == double.infinity ? 200 : cons.maxHeight,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black12
            : const Color(0xFFF0F0F0),
        child: child,
      );
    });
  }

  Widget buildError() {
    return LayoutBuilder(builder: (context, cons) {
      return Container(
        width: cons.maxWidth == double.infinity ? 200 : cons.maxWidth,
        height: cons.maxHeight == double.infinity ? 200 : cons.maxHeight,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black12
            : const Color(0xFFF0F0F0),
        child: const Center(
          child: Icon(
            Icons.broken_image,
            color: Color(0xFFe0e0e0),
            size: 40,
          ),
        ),
      );
    });
  }

  Future<String> getDownloadFuture() {
    if (downloadFuture == null) {
      downloadFuture = _downloadFile();
    }
    return downloadFuture!;
  }

  Future<String> _downloadFile() async {
    if (widget.data.thumbnailPath == null || widget.data.thumbnailPath!.isEmpty)
      return "No download path specified.";
    if (widget.data.thumbnailUrl == null || widget.data.thumbnailUrl!.isEmpty)
      return "No download url specified.";
    fileDownloader ??= FileDownloader();
    return await fileDownloader!
        .download(widget.data.thumbnailUrl!, widget.data.thumbnailPath!);
  }
}
