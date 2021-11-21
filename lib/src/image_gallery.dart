import 'package:flutter/material.dart';
import 'package:image_preview/src/image_view.dart';
import 'package:photo_view/photo_view.dart';

/// 图片加载变化
/// [infoWidget] 当为null时 此图片对应的没有图片描述信息
typedef Future<Widget?> OnPageChanged(int index, Widget? infoWidget);

class ImageGalleryPage extends StatefulWidget {
  ImageGalleryPage({
    Key? key,
    this.initialIndex = 0,
    required this.imageUrls,
    this.imageOriginalUrls,
    this.onLongPressHandler,
    this.heroTags,
    this.errorMsg,
    this.onPageChanged,
  }) : super(key: key) {
    assert(initialIndex >= 0 && initialIndex < imageUrls.length);
    assert(imageOriginalUrls == null || imageOriginalUrls?.length == imageUrls.length);
    assert(heroTags == null || heroTags?.length == imageUrls.length);
  }

  @override
  _ImageGalleryPageState createState() => _ImageGalleryPageState();

  final int initialIndex;

  final List<String> imageUrls;

  final List<String>? imageOriginalUrls;

  final List<String>? heroTags;

  final OnLongPressHandler? onLongPressHandler;

  final String? errorMsg;

  ///第一次打开图片也会被执行
  final OnPageChanged? onPageChanged;
}

class _ImageGalleryPageState extends State<ImageGalleryPage> {
  late PageController _controller;
  late bool _locked;

  final _infoWidgetMap = Map<int, Widget>();

  @override
  void initState() {
    _controller = PageController(initialPage: widget.initialIndex);
    _locked = false;
    super.initState();

    handlerPageChanged(widget.initialIndex);
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
    return widget.imageUrls.length;
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
        child: GestureDetector(
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
              return _buildItem(
                context,
                index,
                widget.errorMsg,
                _infoWidgetMap[index],
              );
            },
            physics: _locked
                ? const NeverScrollableScrollPhysics()
                : ClampingScrollPhysics(),
          ),
        ),
      ),
    );
  }

  void handlerPageChanged(int index) async {
    if (widget.onPageChanged == null) return;
    var tempWidget = await widget.onPageChanged!(index, _infoWidgetMap[index]);
    if(tempWidget == null) return;
    if (mounted) setState(() => _infoWidgetMap[index] = tempWidget);
  }

  Widget _buildItem(
    BuildContext context,
    int index,
    String? errorMsg,
    Widget? infoWidget,
  ) {
    return ClipRect(
      child: ImageView(
        url: widget.imageUrls[index],
        originalUrl: widget.imageOriginalUrls == null
            ? null
            : widget.imageOriginalUrls![index],
        heroTag: widget.heroTags != null
            ? widget.heroTags![index]
            : widget.imageUrls[index],
        scaleStateChangedCallback: scaleStateChangedCallback,
        onLongPressHandler: widget.onLongPressHandler,
        errorMsg: errorMsg,
        infoWidget: infoWidget,
      ),
    );
  }
}
