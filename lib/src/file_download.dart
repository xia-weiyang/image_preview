/// 图片下载

import 'dart:io';
import 'dart:async';

import 'package:flutter/cupertino.dart';

class _DownloaderData {
  _DownloaderData(this.url, this.savePath);

  final url;
  final savePath;
  final callbackList = <_DownloaderCallback>[];
  HttpClientRequest? request;
  List<bool>? isCancel = null;
}

typedef _DownloaderCallback(String result);

final _waitList = <_DownloaderData>[];
final _downloadingList = <_DownloaderData>[];
const _maxDownLoadingNum = 5; // 同时最大的下载个数


HttpClient? _httpClient;

void _download(_DownloaderData data) async {
  final tempCancel = [false];
  data.isCancel = tempCancel;
  try {
    _waitList.remove(data);
    _downloadingList.add(data);

    debugPrint('download:${data.url}');

    _httpClient ??= HttpClient();
    // 创建请求
    data.request = await _httpClient!.getUrl(Uri.parse(data.url));
    // 发送请求并获取响应
    HttpClientResponse response = await data.request!.close();
    // 使用临时文件路径
    String tempFilePath = '${data.savePath}.temp';
    File tempFile = File(tempFilePath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
    await tempFile.create(recursive: true);
    // 将响应内容写入临时文件
    await response.pipe(tempFile.openWrite());

    // 下载完成，将临时文件重命名为目标文件
    if(tempCancel[0]) return;
    File target = File(data.savePath);
    if (await target.exists()) {
      if(tempCancel[0]) return;
      await target.delete();
    }
    if(tempCancel[0]) return;
    await tempFile.rename(target.path);

    // 延迟500ms，避免动画过程中切换图片
    if(tempCancel[0]) return;
    await Future.delayed(Duration(milliseconds: 500));
    if(tempCancel[0]) return;
    debugPrint('File downloaded success! path:${target.path}');
    data.callbackList.forEach((it) {
      it('success');
    });
  } catch (e, stack) {
    debugPrint('Download error: $e \n $stack');
    if(tempCancel[0]) return;
    data.callbackList.forEach((it) {
      it('Download error: $e');
    });
  }

  _downloadingList.remove(data);
  // 开始新的下载
  _startNewDownload();
}

void _startNewDownload(){
  // 开始新的下载
  if (_downloadingList.length < _maxDownLoadingNum) {
    if (_waitList.isNotEmpty) {
      final temp = _waitList[0];
      _waitList.removeAt(0);
      _download(temp);
    }
  }
}

class FileDownloader {
  _DownloaderData? data;
  _DownloaderCallback? callback;

  /**
   * 开始下载某一文件
   */
  Future<String> download(String url, String savePath) async {
    final completer = Completer<String>();
    // 检查有无下载的是重复文件
    var findIndex = _downloadingList.indexWhere((it) => it.url == url);
    if (findIndex >= 0) {
      data = _downloadingList[findIndex];
    } else {
      findIndex = _waitList.indexWhere((it) => it.url == url);
      if (findIndex >= 0) {
        data = _waitList[findIndex];
      }
    }
    if (data != null) {
      data!.callbackList.add(callback = (result) => completer.complete(result));
      return completer.future;
    }

    data = _DownloaderData(url, savePath);
    data!.callbackList.add(callback = (result) => completer.complete(result));
    // 下载队列已满
    if (_downloadingList.length >= _maxDownLoadingNum) {
      _waitList.add(data!);
      return completer.future;
    }

    // 执行下载
    _download(data!);
    return completer.future;
  }

  Future<void> cancel() async {
    if (data != null) {
      if (callback != null) {
        data!.callbackList.remove(callback!);
      }
      if (data!.callbackList.isEmpty) {
        // 中断请求
        if (data!.request != null) {
          data!.request!.abort();
          data!.request = null;
          if(data!.isCancel != null){
            data!.isCancel![0] = true;
          }
          debugPrint('download cancel:${data!.url}');
          _downloadingList.remove(data);
          _startNewDownload();
        }
      }
    }
  }
}
