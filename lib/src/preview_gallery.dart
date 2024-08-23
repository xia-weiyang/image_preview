import 'package:flutter/material.dart';
import 'package:image_preview/preview.dart';
import 'package:image_preview/preview_data.dart';
import 'package:image_preview/src/image_view.dart';
import 'package:photo_view/photo_view.dart';

class ImageGalleryPage extends StatefulWidget {
  ImageGalleryPage({
    Key? key,
    required this.data,
    this.initialIndex = 0,
    this.indicator = false,
    this.onLongPressHandler,
    this.onPageChanged,
    this.tipWidget,
  }) : super(key: key) {}

  @override
  _ImageGalleryPageState createState() => _ImageGalleryPageState();

  final int initialIndex;

  /// 是否显示左右切换按钮
  final bool indicator;

  final List<PreviewData> data;

  final OnLongPressHandler? onLongPressHandler;

  ///第一次打开图片也会被执行
  final OnPageChanged? onPageChanged;

  final Widget? tipWidget;
}

class _ImageGalleryPageState extends State<ImageGalleryPage> {
  late PageController _controller;
  late bool _locked;
  var firstOpen = true;
  var currentPage = -1;

  @override
  void initState() {
    _controller = PageController(initialPage: widget.initialIndex);
    _locked = false;
    currentPage = widget.initialIndex;
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      handlerPageChanged(widget.initialIndex);
    });
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
    return _controller.hasClients ? _controller.page?.floor() ?? 0 : 0;
  }

  int get itemCount {
    return widget.data.length;
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
        child: Stack(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              onDoubleTap: () {},
              child: PageView.builder(
                controller: _controller,
                itemCount: itemCount,
                onPageChanged: (index) {
                  // print(index);
                  handlerPageChanged(index);
                },
                itemBuilder: (BuildContext context, int index) {
                  final widget = _buildItem(
                    context,
                    index,
                  );
                  firstOpen = false;
                  return widget;
                },
                physics: _locked
                    ? const NeverScrollableScrollPhysics()
                    : ClampingScrollPhysics(),
              ),
            ),
            if (widget.tipWidget != null) widget.tipWidget!,
            if (widget.indicator)
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(left: 32, right: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      currentPage > 0
                          ? IndicatorWidget(
                              icon: Icons.chevron_left_outlined,
                              onTap: () {
                                _controller.previousPage(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            )
                          : const SizedBox(),
                      currentPage < itemCount - 1
                          ? IndicatorWidget(
                              icon: Icons.chevron_right_outlined,
                              onTap: () {
                                _controller.nextPage(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            )
                          : const SizedBox(),
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  void handlerPageChanged(int index) async {
    if (currentPage != index) {
      setState(() {
        currentPage = index;
      });
      debugPrint('currentPage $currentPage');
    }
    if (widget.onPageChanged == null) return;
    widget.onPageChanged!(currentPage);
  }

  Widget _buildItem(
    BuildContext context,
    int index,
  ) {
    final preview = widget.data[index];
    if (preview.type == Type.image) {
      return ClipRect(
        child: ImagePreview(
          data: preview.image!,
          heroTag: preview.heroTag ?? '',
          open: firstOpen && index == widget.initialIndex,
          scaleStateChangedCallback: scaleStateChangedCallback,
          onLongPressHandler: widget.onLongPressHandler,
        ),
      );
    } else {
      return SizedBox();
    }
  }
}

class IndicatorWidget extends StatefulWidget {
  const IndicatorWidget({
    super.key,
    required this.icon,
    this.onTap,
  });

  final IconData icon;
  final GestureTapCallback? onTap;

  @override
  State<StatefulWidget> createState() => IndicatorWidgetState();
}

class IndicatorWidgetState extends State<IndicatorWidget> {
  var colorAlpha = 0;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: GestureDetector(
        onTapDown: (details) {
          setState(() {
            colorAlpha = 50;
          });
        },
        onTapUp: (details) {
          setState(() {
            colorAlpha = 0;
          });
        },
        onTap: widget.onTap,
        child: Container(
          width: 40,
          height: 40,
          color: Colors.white.withAlpha(30 + colorAlpha),
          child: Center(
            child: Icon(
              widget.icon,
              color: Colors.white.withAlpha(180 + colorAlpha),
            ),
          ),
        ),
      ),
    );
  }
}
