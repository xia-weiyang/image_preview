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
    this.fit = BoxFit.cover,
    this.onTap,
    this.onLongTap,
  });

  final PreviewData data;
  final BoxFit fit;
  final VoidCallback? onTap;
  final VoidCallback? onLongTap;

  @override
  State<StatefulWidget> createState() => PreviewThumbnailState();
}

class PreviewThumbnailState extends State<PreviewThumbnail> {
  @override
  Widget build(BuildContext context) {
    Widget child;

    if (widget.data.type == Type.image) {
      child = ImagePreviewThumbnailView(
        data: widget.data.image!,
        fit: widget.fit,
      );
    } else {
      child = Container();
    }
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongTap,
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
  Widget? tipWidget,
  OnLongPressHandler? onLongPressHandler,
  OnPageChanged? onPageChanged,
}) {
  navigatorState.push(FadePageRoute<void>(builder: (BuildContext context) {
    return ImageGalleryPage(
      data: [data],
      tipWidget: tipWidget,
      onLongPressHandler: onLongPressHandler,
      onPageChanged: onPageChanged,
    );
  }));
}

/// 打开多张图片
/// [indicator] 是否显示左右切换的按钮
/// [onPageChanged] 切换图片时调用，第一次打开时也会被调用
/// 返回的[Widget]可用于展示图片描述信息，如不需要可返回null
void openPreviewPages(
  NavigatorState navigatorState, {
  required List<PreviewData> data,
  int index = 0,
  bool indicator = false,
  Widget? tipWidget,
  OnLongPressHandler? onLongPressHandler,
  OnPageChanged? onPageChanged,
}) {
  navigatorState.push(FadePageRoute<void>(builder: (BuildContext context) {
    return ImageGalleryPage(
      data: data,
      initialIndex: index,
      indicator: indicator,
      tipWidget: tipWidget,
      onLongPressHandler: onLongPressHandler,
      onPageChanged: onPageChanged,
    );
  }));
}

/// 图片加载变化
typedef void OnPageChanged(int index);
