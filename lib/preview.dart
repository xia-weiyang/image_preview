library image_preview;

import 'package:flutter/material.dart';
import 'package:image_preview/preview_data.dart';
import 'package:image_preview/src/image_preview_view.dart';
import 'package:image_preview/src/preview_gallery.dart';
import 'package:image_preview/src/page_route.dart';
import 'package:image_preview/src/video_preview_view.dart';
import 'package:video_player/video_player.dart';

class PreviewThumbnail extends StatefulWidget {
  const PreviewThumbnail({
    super.key,
    required this.data,
    this.fit = BoxFit.cover,
    this.onTap,
    this.onLongTap,
    this.videoShowPlayIcon = true,
    this.videoPlayIconSize = 50,
  });

  final PreviewData data;
  final BoxFit fit;
  final VoidCallback? onTap;
  final VoidCallback? onLongTap;
  final bool videoShowPlayIcon;
  final double videoPlayIconSize;

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
    } else if (widget.data.type == Type.video) {
      child = VideoPreviewCoverWidget(
        data: widget.data.video!,
        fit: widget.fit,
        showPlayIcon: widget.videoShowPlayIcon,
        playIconSize: widget.videoPlayIconSize,
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
  Key? key,
  BuildTipWidget? tipWidget,
  bool disableOnTap = false,
  OnLongPressHandler? onLongPressHandler,
  OnPageChanged? onPageChanged,
  OnPlayError? onPlayError,
  OnPlayControllerListener? onPlayControllerListener,
  double extraVideoBottomPadding = 0,
}) {
  navigatorState.push(FadePageRoute<void>(builder: (BuildContext context) {
    return ImageGalleryPage(
      key: key,
      data: [data],
      tipWidget: tipWidget,
      disableOnTap: disableOnTap,
      onLongPressHandler: onLongPressHandler,
      onPageChanged: onPageChanged,
      onPlayError: onPlayError,
      onPlayControllerListener: onPlayControllerListener,
      extraVideoBottomPadding: extraVideoBottomPadding,
    );
  }));
}

/// 打开多张图片
/// [indicator] 是否显示左右切换的按钮
/// [onPageChanged] 切换图片时调用，第一次打开时也会被调用
/// 返回的[tipWidget]可用于展示图片描述信息，如不需要可返回null
void openPreviewPages(
  NavigatorState navigatorState, {
  required List<PreviewData> data,
  Key? key,
  int index = 0,
  bool indicator = false,
  BuildTipWidget? tipWidget,
  bool disableOnTap = false,
  OnLongPressHandler? onLongPressHandler,
  OnPageChanged? onPageChanged,
  OnPlayError? onPlayError,
  OnPlayControllerListener? onPlayControllerListener,
  double extraVideoBottomPadding = 0,
}) {
  navigatorState.push(FadePageRoute<void>(builder: (BuildContext context) {
    return ImageGalleryPage(
      data: data,
      key: key,
      initialIndex: index,
      indicator: indicator,
      tipWidget: tipWidget,
      disableOnTap: disableOnTap,
      onLongPressHandler: onLongPressHandler,
      onPageChanged: onPageChanged,
      onPlayError: onPlayError,
      onPlayControllerListener: onPlayControllerListener,
      extraVideoBottomPadding: extraVideoBottomPadding,
    );
  }));
}

/// 图片加载变化
typedef void OnPageChanged(int index);

// 构建TipWidget
typedef Widget? BuildTipWidget(int index);

typedef OnPlayControllerListener(VideoPlayerController controller);

typedef OnPlayError(String msg);
