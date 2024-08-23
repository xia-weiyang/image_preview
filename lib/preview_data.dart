import 'dart:convert';

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

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'heroTag': heroTag,
      'image': image?.toJson(),
    };
  }

  factory PreviewData.fromJson(Map<String, dynamic> json) {
    final image = json['image'];
    return PreviewData(
      type: Type.values.firstWhere((it) => json['type'] as String == it.name),
      heroTag: json['heroTag'] as String,
      image: image == null ? null : ImageData.fromJson(json['image']),
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'path': path,
      'thumbnailUrl': thumbnailUrl,
      'thumbnailPath': thumbnailPath,
    };
  }

  factory ImageData.fromJson(Map<String, dynamic> json) {
    final url = json['url'];
    final path = json['path'];
    final thumbnailUrl = json['thumbnailUrl'];
    final thumbnailPath = json['thumbnailPath'];
    return ImageData(
      url: url == null ? null : url as String,
      path: path == null ? null : path as String,
      thumbnailUrl: thumbnailUrl == null ? null : thumbnailUrl as String,
      thumbnailPath: thumbnailPath == null ? null : thumbnailPath as String,
    );
  }
}

String convertPreviewDataListToJson(List<PreviewData> data) {
  return jsonEncode(data);
}

List<PreviewData> convertJsonToPreviewDataList(String json) {
  return (jsonDecode(json) as List)
      .map((it) => PreviewData.fromJson(it))
      .toList();
}
