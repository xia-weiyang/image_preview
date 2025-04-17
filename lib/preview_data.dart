import 'dart:convert';

import 'package:flutter/cupertino.dart';

/// 类型
enum Type { image, video }

/// 打开预览图片需要的数据类型
class PreviewData {
  const PreviewData({
    required this.type,
    this.heroTag,
    this.image,
    this.video,
  });

  final Type type;

  final ImageData? image;
  final VideoData? video;

  final String? heroTag;

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'heroTag': heroTag,
      'image': image?.toJson(),
      'video': video?.toJson(),
    };
  }

  factory PreviewData.fromJson(Map<String, dynamic> json) {
    final image = json['image'];
    final video = json['video'];
    return PreviewData(
      type: Type.values.firstWhere((it) => json['type'] as String == it.name),
      heroTag: json['heroTag'] as String,
      image: image == null ? null : ImageData.fromJson(image),
      video: video == null ? null : VideoData.fromJson(video),
    );
  }
}

class ImageData {
  const ImageData({
    this.path,
    this.url,
    this.asyncPath,
    this.thumbnailUrl,
    this.thumbnailPath,
    this.thumbnailProvide,
  });

  final String? url;

  /// 图片文件的缓存路径
  final String? path;

  /// 异步获取图片路径
  final AsyncPath? asyncPath;

  /// 缩略图的本地路径
  final String? thumbnailPath;

  /// 缩略图地址
  final String? thumbnailUrl;

  /// 缩略图数据
  final ImageProvider? thumbnailProvide;

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

class VideoData {
  const VideoData({
    this.coverPath,
    this.coverUrl,
    this.coverProvide,
    this.url,
    this.asyncPath,
  });

  /// 视频封面缓存路径
  final String? coverPath;

  /// 视频封面地址
  final String? coverUrl;

  final ImageProvider? coverProvide;

  /// 视频地址
  final String? url;

  /// 异步获取图片路径
  final AsyncPath? asyncPath;

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'coverUrl': coverUrl,
      'coverPath': coverPath,
    };
  }

  factory VideoData.fromJson(Map<String, dynamic> json) {
    final url = json['url'];
    final coverUrl = json['coverUrl'];
    final coverPath = json['coverPath'];
    return VideoData(
      url: url == null ? null : url as String,
      coverUrl: coverUrl == null ? null : coverUrl as String,
      coverPath: coverPath == null ? null : coverPath as String,
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

typedef Future<String> AsyncPath();
