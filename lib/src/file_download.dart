/// 图片下载

import 'dart:io';
import 'dart:async';

import 'package:flutter/cupertino.dart';

class FileDownloader {
  HttpClient? httpClient;
  HttpClientRequest? request;

  Future<String> download(String url, String savePath) async {
    try {
      debugPrint('download:$url');

      cancel();

      httpClient ??= HttpClient();
      // 创建请求
      request = await httpClient!.getUrl(Uri.parse(url));
      // 发送请求并获取响应
      HttpClientResponse response = await request!.close();
      // 使用临时文件路径
      String tempFilePath = '$savePath.temp';
      File tempFile = File(tempFilePath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      await tempFile.create(recursive: true);
      // 将响应内容写入临时文件
      await response.pipe(tempFile.openWrite());
      httpClient!.close();

      // 下载完成，将临时文件重命名为目标文件
      File target = File(savePath);
      if (await target.exists()) {
        await target.delete();
      }
      await tempFile.rename(target.path);
      debugPrint('File downloaded success! path:${target.path}');

      // 延迟500ms，避免动画过程中切换图片
      await Future.delayed(Duration(milliseconds: 500));

      return 'success';
    } catch (e, stack) {
      debugPrint('Download error: $e \n $stack');
      return 'Download error: $e';
    }
  }

  Future<void> cancel() async {
    if (request != null) {
      request!.abort();
      request = null;
    }
    if (httpClient != null) {
      httpClient!.close(force: true);
      httpClient = null;
    }
  }
}
