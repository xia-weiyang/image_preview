import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';

class ImageView extends StatefulWidget {
  const ImageView({
    Key key,
    @required this.url,
    this.heroTag,
  }) : super(key: key);

  @override
  _ImageViewState createState() => _ImageViewState();

  final String url;

  final String heroTag;
}

class _ImageViewState extends State<ImageView> {
  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: widget.url,
      placeholder: (context, str) => ImageLoading(),
      imageBuilder: (context, provider) {
        return GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: PhotoView(
            imageProvider: provider,
            heroTag: widget.heroTag,
            loadingChild: ImageLoading(),
            minScale: PhotoViewComputedScale.contained * 1.0,
            maxScale: PhotoViewComputedScale.covered * 3.0,
          ),
        );
      },
    );
  }
}

class ImageLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: SizedBox(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
      ),
    ));
  }
}
