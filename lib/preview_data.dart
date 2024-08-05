/// 类型
enum Type { image, video }

/// 打开预览图片需要的数据类型
class PreviewData {
  const PreviewData({
    required this.type,
    this.heroTag,
    this.image,
  });

  final Type type;

  final ImageData? image;

  final String? heroTag;
}

class ImageData {
  const ImageData({
    this.path,
    this.url,
    this.thumbnailUrl,
    this.thumbnailPath,
  });

  final String? url;

  /// 图片文件的缓存路径
  final String? path;

  /// 缩略图的本地路径
  final String? thumbnailPath;

  /// 缩略图地址
  final String? thumbnailUrl;
}
