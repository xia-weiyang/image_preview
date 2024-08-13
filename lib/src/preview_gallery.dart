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
    this.onLongPressHandler,
    this.onPageChanged,
  }) : super(key: key) {}

  @override
  _ImageGalleryPageState createState() => _ImageGalleryPageState();

  final int initialIndex;

  final List<PreviewData> data;

  final OnLongPressHandler? onLongPressHandler;

  ///第一次打开图片也会被执行
  final OnPageChanged? onPageChanged;
}

class _ImageGalleryPageState extends State<ImageGalleryPage> {
  late PageController _controller;
  late bool _locked;
  var firstOpen = true;

  final _infoWidgetMap = Map<int, Widget>();

  @override
  void initState() {
    _controller = PageController(initialPage: widget.initialIndex);
    _locked = false;
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
              final widget = _buildItem(
                context,
                index,
                _infoWidgetMap[index],
              );
              firstOpen = false;
              return widget;
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
    if (tempWidget == null) return;
    if (mounted) setState(() => _infoWidgetMap[index] = tempWidget);
  }

  Widget _buildItem(
    BuildContext context,
    int index,
    Widget? infoWidget,
  ) {
    final preview = widget.data[index];
    if (preview.type == Type.image) {
      return ClipRect(
        child: ImageView(
          data: preview.image!,
          heroTag: preview.heroTag ?? '',
          open: firstOpen && index == widget.initialIndex,
          scaleStateChangedCallback: scaleStateChangedCallback,
          onLongPressHandler: widget.onLongPressHandler,
          infoWidget: infoWidget,
        ),
      );
    } else {
      return SizedBox();
    }
  }
}
