import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_preview/preview_data.dart';
import 'package:image_preview/src/file_download.dart';

class VideoPreviewCoverWidget extends StatefulWidget {
  const VideoPreviewCoverWidget({
    super.key,
    required this.data,
    required this.fit,
    required this.playIconSize,
    required this.showPlayIcon,
  });

  final VideoData data;
  final BoxFit fit;
  final double playIconSize;
  final bool showPlayIcon;

  @override
  State<StatefulWidget> createState() => _VideoPreviewCoverWidgetState();
}

class _VideoPreviewCoverWidgetState extends State<VideoPreviewCoverWidget> {
  FileDownloader? fileDownloader;
  Future<String>? downloadFuture;

  @override
  void dispose() {
    fileDownloader?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant VideoPreviewCoverWidget oldWidget) {
    if (widget.data.coverUrl != oldWidget.data.coverUrl ||
        widget.data.coverPath != oldWidget.data.coverPath) {
      fileDownloader?.cancel();
      fileDownloader = null;
      downloadFuture = null;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.coverProvide != null) {
      return buildPlayIconWidget(Image(
        image: widget.data.coverProvide!,
        fit: widget.fit,
      ));
    }

    if (kIsWeb) {
      if (widget.data.coverUrl == null || widget.data.coverUrl!.isEmpty) {
        return buildError();
      }
      return buildPlaceholder(
        child: buildPlayIconWidget(Image(
          image: NetworkImage(widget.data.coverUrl ?? ''),
          errorBuilder: (con, error, stack) {
            return buildError();
          },
          fit: widget.fit,
        )),
      );
    }
    return _existFile()
        ? buildPlayIconWidget(Image(
            image: FileImage(File.fromUri(Uri.file(widget.data.coverPath!))),
            fit: widget.fit,
          ))
        : FutureBuilder(
            future: getDownloadFuture(),
            builder: (_, snapshot) {
              if (snapshot.hasData) {
                if ('success' == snapshot.data) {
                  return buildPlayIconWidget(Image(
                    image: FileImage(
                        File.fromUri(Uri.file(widget.data.coverPath!))),
                    fit: widget.fit,
                  ));
                } else {
                  return buildError();
                }
              }
              return buildPlaceholder();
            });
  }

  Widget buildPlayIconWidget(Widget child) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          child: child,
        ),
        if (widget.showPlayIcon)
          Center(
            child: Opacity(
              opacity: 0.5,
              child: Icon(
                Icons.play_circle_outline,
                color: Color(0xFFEEEEEE),
                size: widget.playIconSize,
              ),
            ),
          ),
      ],
    );
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

  /// 检查是否存在缓存文件
  bool _existFile() {
    if (widget.data.coverPath == null) return false;
    final file = File(widget.data.coverPath!);
    bool result = file.existsSync();
    return result;
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
    if (widget.data.coverPath == null || widget.data.coverPath!.isEmpty)
      return "No download path specified.";
    if (widget.data.coverUrl == null || widget.data.coverUrl!.isEmpty)
      return "No download url specified.";
    fileDownloader ??= FileDownloader();
    return await fileDownloader!
        .download(widget.data.coverUrl!, widget.data.coverPath!);
  }
}
