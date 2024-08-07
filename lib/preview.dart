library image_preview;

import 'package:flutter/material.dart';
import 'package:image_preview/preview_data.dart';
import 'package:image_preview/src/image_preview_view.dart';
import 'package:image_preview/src/preview_gallery.dart';
import 'package:image_preview/src/image_view.dart';
import 'package:image_preview/src/page_route.dart';

class PreviewThumbnail extends StatefulWidget {
  const PreviewThumbnail({
    super.key,
    required this.data,
    this.onTap,
  });

  final PreviewData data;
  final VoidCallback? onTap;

  @override
  State<StatefulWidget> createState() => PreviewThumbnailState();
}

class PreviewThumbnailState extends State<PreviewThumbnail> {
  @override
  Widget build(BuildContext context) {
    Widget child;

    if (widget.data.type == Type.image) {
      child = ImagePreviewThumbnailView(data: widget.data.image!);
    } else {
      child = Container();
    }
    return GestureDetector(
      onTap: widget.onTap,
      child: Hero(
        tag: widget.data.heroTag ?? '',
        child: child,
      ),
    );
  }
}

/// 打开单张预览
void openPreviewPage(
  NavigatorState navigatorState, {
  required PreviewData data,
  OnLongPressHandler? onLongPressHandler,
  OnPageChanged? onPageChanged,
}) {
  navigatorState.push(FadePageRoute<void>(builder: (BuildContext context) {
    return ImageGalleryPage(
      data: [data],
      onLongPressHandler: onLongPressHandler,
      onPageChanged: onPageChanged,
    );
  }));
}

/// 打开多张图片
/// [onPageChanged] 切换图片时调用，第一次打开时也会被调用
/// 返回的[Widget]可用于展示图片描述信息，如不需要可返回null
void openPreviewPages(
  NavigatorState navigatorState, {
  required List<PreviewData> data,
  int index = 0,
  OnLongPressHandler? onLongPressHandler,
  OnPageChanged? onPageChanged,
}) {
  navigatorState.push(FadePageRoute<void>(builder: (BuildContext context) {
    return ImageGalleryPage(
      data: data,
      initialIndex: index,
      onLongPressHandler: onLongPressHandler,
      onPageChanged: onPageChanged,
    );
  }));
}

/// 图片加载变化
/// [infoWidget] 当为null时 此图片对应的没有图片描述信息
typedef Future<Widget?> OnPageChanged(int index, Widget? infoWidget);
