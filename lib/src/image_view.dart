import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_preview/preview_data.dart';
import 'package:image_preview/src/file_download.dart';
import 'package:image_preview/src/preview_gallery.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:video_player/video_player.dart';

class ImagePreview extends StatefulWidget {
  const ImagePreview({
    super.key,
    required this.data,
    required this.heroTag,
    required this.open,
    this.onLongPressHandler,
    this.scaleStateChangedCallback,
    this.onPlayStateListener,
  });

  final ImageData data;
  final String heroTag;
  final bool open;
  final OnLongPressHandler? onLongPressHandler;
  final ValueChanged<PhotoViewScaleState>? scaleStateChangedCallback;

  /// 实况图视频播放状态变化
  final ValueChanged<bool>? onPlayStateListener;

  @override
  State<StatefulWidget> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  FileDownloader? fileDownloader;
  Future<String>? downloadFuture;
  final delay = Future.delayed(Duration(milliseconds: 500));
  var open = false;
  ImageProvider? imageProvide;
  ImageProvider? imageProvideThumbnail;
  String? _targetPath;

  /// 实况图视频控制器
  VideoPlayerController? _liveController;

  /// 实况图视频是否已加载完成
  var _livePrepared = false;

  /// 实况图视频是否正在播放
  var _livePlaying = false;

  /// 是否已自动播放过，保证只自动播放一次
  var _autoPlayed = false;

  Timer? _autoPlayTimer;

  /// 实况图视频下载器
  FileDownloader? _liveDownloader;

  /// 实况图视频是否正在下载
  var _liveLoading = false;

  bool get _isLivePhoto => widget.data.isLivePhoto;

  /// Windows、Linux 不支持内嵌播放视频，使用外部播放器打开
  bool get _liveUseExternalPlayer =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux);

  @override
  void initState() {
    open = widget.open;
    _targetPath = widget.data.path;
    if (widget.data.url != null && widget.data.url!.isNotEmpty) {
      imageProvide = NetworkImage(widget.data.url!);
    }
    if (widget.data.thumbnailUrl != null &&
        widget.data.thumbnailUrl!.isNotEmpty) {
      imageProvideThumbnail = NetworkImage(widget.data.thumbnailUrl!);
    }
    super.initState();
    if (_isLivePhoto) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _prepareLivePlay();
      });
    }
  }

  @override
  void dispose() {
    _disposeLiveController();
    fileDownloader?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ImagePreview oldWidget) {
    if (widget.data.url != oldWidget.data.url ||
        widget.data.asyncPath != widget.data.asyncPath ||
        widget.data.path != oldWidget.data.path) {
      _targetPath = widget.data.path;
      fileDownloader?.cancel();
      fileDownloader = null;
      downloadFuture = null;
    }
    if (widget.data.videoUrl != oldWidget.data.videoUrl ||
        widget.data.videoPath != oldWidget.data.videoPath) {
      _disposeLiveController();
      _autoPlayed = false;
      if (_isLivePhoto) {
        _prepareLivePlay();
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  /// 确保实况图视频已缓存到本地，返回本地视频路径，失败返回 null
  Future<String?> _ensureLocalVideo() async {
    final videoUrl = widget.data.videoUrl;
    final videoPath = widget.data.videoPath;
    if (videoPath == null || videoPath.isEmpty) {
      debugPrint('live photo video path is empty');
      return null;
    }
    if (File(videoPath).existsSync()) {
      return videoPath;
    }
    if (videoUrl == null || videoUrl.isEmpty) {
      debugPrint('live photo video url is empty');
      return null;
    }
    if (!mounted) return null;
    setState(() {
      _liveLoading = true;
    });
    _liveDownloader ??= FileDownloader();
    final result = await _liveDownloader!.download(videoUrl, videoPath);
    if (!mounted) return null;
    setState(() {
      _liveLoading = false;
    });
    if (result != 'success') {
      debugPrint('live photo video download error: $result');
      return null;
    }
    return videoPath;
  }

  /// 加载实况图视频：本地不存在时先下载，初始化后延迟1秒自动播放一次
  void _prepareLivePlay() async {
    if (!_isLivePhoto) return;
    // web 没有文件系统，无法缓存到本地，只能播放网络地址
    if (kIsWeb) {
      final videoUrl = widget.data.videoUrl;
      if (videoUrl == null || videoUrl.isEmpty) {
        debugPrint('live photo video url is empty');
        return;
      }
      _initLiveController(videoUrl, network: true);
      return;
    }
    final localPath = await _ensureLocalVideo();
    if (localPath == null) return;
    // 桌面平台不支持内嵌播放视频，使用外部播放器打开本地文件
    if (_liveUseExternalPlayer) {
      if (!mounted) return;
      setState(() {
        _livePrepared = true;
      });
      return;
    }
    _initLiveController(localPath, network: false);
  }

  /// 创建并初始化实况图视频控制器
  void _initLiveController(String path, {required bool network}) async {
    final controller = network
        ? VideoPlayerController.networkUrl(Uri.parse(path))
        : VideoPlayerController.file(File(path));
    _liveController = controller;
    try {
      await controller.initialize();
    } catch (e) {
      debugPrint('live photo video init error: $e');
      controller.dispose();
      return;
    }
    if (!mounted || _liveController != controller) {
      controller.dispose();
      return;
    }
    await controller.setLooping(false);
    controller.addListener(_liveListener);
    setState(() {
      _livePrepared = true;
    });
    // web 平台受浏览器自动播放策略限制，不自动播放，需用户点击实况按钮
    if (kIsWeb) return;
    // 视频加载完成后延迟1秒自动播放一次
    _autoPlayTimer = Timer(Duration(seconds: 1), () {
      if (!mounted || _autoPlayed) return;
      _autoPlayed = true;
      _playLive();
    });
  }

  void _disposeLiveController() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
    _liveDownloader?.cancel();
    _liveDownloader = null;
    _liveLoading = false;
    final controller = _liveController;
    _liveController = null;
    _livePrepared = false;
    _livePlaying = false;
    if (controller != null) {
      controller.removeListener(_liveListener);
      controller.dispose();
    }
  }

  void _liveListener() {
    final controller = _liveController;
    if (controller == null) return;
    final value = controller.value;
    if (value.hasError) {
      debugPrint('live photo play error: ${value.errorDescription}');
      _stopLive();
      return;
    }
    // 播放完成，恢复为静态图片
    if (_livePlaying &&
        !value.isPlaying &&
        value.duration > Duration.zero &&
        value.position >= value.duration) {
      _stopLive();
    }
  }

  void _playLive() async {
    final controller = _liveController;
    if (controller == null || !_livePrepared || _livePlaying) return;
    if (!mounted) return;
    setState(() {
      _livePlaying = true;
    });
    widget.onPlayStateListener?.call(true);
    try {
      await controller.seekTo(Duration.zero);
      await controller.play();
    } catch (e) {
      debugPrint('live photo play error: $e');
      _stopLive();
    }
  }

  void _stopLive() async {
    if (!mounted || !_livePlaying) return;
    setState(() {
      _livePlaying = false;
    });
    widget.onPlayStateListener?.call(false);
    final controller = _liveController;
    if (controller == null) return;
    await controller.pause();
    await controller.seekTo(Duration.zero);
  }

  void _toggleLive() async {
    if (_liveLoading) return;
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
    _autoPlayed = true;
    // 桌面平台不支持内嵌播放视频，使用外部播放器打开本地文件
    if (_liveUseExternalPlayer) {
      final videoPath = widget.data.videoPath;
      if (videoPath != null &&
          videoPath.isNotEmpty &&
          File(videoPath).existsSync()) {
        await launchUrlString(
          Uri.file(videoPath).toString(),
          mode: LaunchMode.externalApplication,
        );
        return;
      }
      final localPath = await _ensureLocalVideo();
      if (localPath != null) {
        await launchUrlString(
          Uri.file(localPath).toString(),
          mode: LaunchMode.externalApplication,
        );
      }
      return;
    }
    if (_livePlaying) {
      _stopLive();
      return;
    }
    if (_livePrepared) {
      _playLive();
    } else if (_liveController == null) {
      _prepareLivePlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果是web环境，直接加载网络图片
    if (kIsWeb) {
      return _buildWeb();
    }

    return _existFile()
        ? open
            ? FutureBuilder(
                future: delay,
                builder: (_, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return _buildImageWidgetPre();
                  }
                  return ImageLoading(
                    tag: widget.heroTag,
                    showLoading: false,
                    provider: widget.data.thumbnailProvide,
                    path: _existThumbnailFile()
                        ? widget.data.thumbnailPath
                        : null,
                  );
                },
              )
            : _buildImageWidgetPre()
        : FutureBuilder(
            future: getDownloadFuture(),
            builder: (_, snapshot) {
              if (snapshot.hasData) {
                if ('success' == snapshot.data) {
                  return _buildImageWidgetPre();
                } else {
                  return ImageError(
                    msg: 'Image load failed',
                    describe: '${widget.data.url}\n${snapshot.data}',
                  );
                }
              } else {
                return ImageLoading(
                  tag: widget.heroTag,
                  provider: widget.data.thumbnailProvide,
                  path:
                      _existThumbnailFile() ? widget.data.thumbnailPath : null,
                );
              }
            });
  }

  Widget _buildWeb() {
    if (widget.data.url == null || widget.data.url!.isEmpty) {
      return ImageError(
        msg: 'Image load failed',
        describe: 'Url is empty',
      );
    }
    return open
        ? FutureBuilder(
            future: delay,
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return _buildImageWidgetPreWeb();
              }
              return imageProvideThumbnail == null
                  ? SizedBox()
                  : Align(
                      alignment: Alignment.center,
                      child: Hero(
                        child: Container(
                          width: double.infinity,
                          child: Image(
                            image: imageProvideThumbnail!,
                            fit: BoxFit.contain,
                          ),
                        ),
                        tag: widget.heroTag,
                      ),
                    );
            },
          )
        : _buildImageWidgetPreWeb();
  }

  Widget _buildImageWidgetPreWeb() {
    Widget? image = null;
    if (widget.data.thumbnailProvide != null) {
      image = Image(image: widget.data.thumbnailProvide!, fit: BoxFit.contain);
    } else if (imageProvideThumbnail != null) {
      image = Image(
        image: imageProvideThumbnail!,
        fit: BoxFit.contain,
      );
    }

    return _buildImageWidget(imageProvide!, image);
  }

  Widget _buildImageWidgetPre() {
    Widget? image = null;
    if (widget.data.thumbnailProvide != null) {
      image = Image(image: widget.data.thumbnailProvide!, fit: BoxFit.contain);
    } else if (_existThumbnailFile()) {
      image = Image(
        image: FileImage(File.fromUri(Uri.file(widget.data.thumbnailPath!))),
        fit: BoxFit.contain,
      );
    }
    return _buildImageWidget(
      FileImage(File.fromUri(Uri.file(_targetPath ?? ''))),
      image,
    );
  }

  Widget _buildImageWidget(ImageProvider imageProvide, [Widget? loadImage]) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 实况图视频层常驻最底层，避免 web 平台反复卸载平台视图导致再次播放黑屏
        if (_livePrepared && _liveController != null) _buildLiveVideo(),
        // 播放时隐藏图片，停止播放后图片重新覆盖视频
        IgnorePointer(
          ignoring: _livePlaying,
          child: Opacity(
            opacity: _livePlaying ? 0 : 1,
            child: GestureDetector(
              onLongPress: () {
                if (widget.onLongPressHandler != null) {
                  widget.onLongPressHandler!(
                      context,
                      PreviewData(
                        type: Type.image,
                        image: widget.data,
                      ));
                }
              },
              child: PhotoView(
                imageProvider: imageProvide,
                loadingBuilder: loadImage == null
                    ? (_, event) {
                        return ImageLoading();
                      }
                    : (_, event) {
                        return Center(
                          child: Container(
                            width: double.infinity,
                            child: loadImage,
                          ),
                        );
                      },
                heroAttributes: PhotoViewHeroAttributes(tag: widget.heroTag),
                scaleStateChangedCallback: widget.scaleStateChangedCallback,
                minScale: PhotoViewComputedScale.contained * 1.0,
                maxScale: PhotoViewComputedScale.covered * 3.0,
                errorBuilder: (_, msg, stack) {
                  print('PhotoView error: $msg \n $stack');
                  return ImageError(
                    msg: 'Image load failed',
                    describe: '${widget.data.url}\n${msg}',
                  );
                },
              ),
            ),
          ),
        ),
        if (_isLivePhoto) _buildLiveButton(),
      ],
    );
  }

  /// 实况图视频画面，播放时覆盖在图片之上
  Widget _buildLiveVideo() {
    final controller = _liveController!;
    var rotationCorrection = 0;
    try {
      rotationCorrection = controller.value.rotationCorrection;
    } catch (e) {}
    var aspectRatio = controller.value.aspectRatio;
    if (rotationCorrection == 90 || rotationCorrection == 270) {
      aspectRatio = 1 / aspectRatio;
    }
    return Align(
      alignment: Alignment.center,
      child: IgnorePointer(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  /// 底部实况按钮
  Widget _buildLiveButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        child: GestureDetector(
          onTap: _toggleLive,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(80),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _liveLoading
                    ? SizedBox(
                        width: 10,
                        height: 10,
                        child: !kIsWeb && (Platform.isIOS || Platform.isMacOS)
                            ? const CupertinoActivityIndicator(
                                radius: 6,
                                color: Color(0xFFDDDDDD),
                              )
                            : const CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFDDDDDD)),
                              ),
                      )
                    : Icon(
                        _livePlaying
                            ? Icons.motion_photos_pause
                            : Icons.motion_photos_on,
                        size: 16,
                        color: Color(0xFFDDDDDD),
                      ),
                const SizedBox(width: 4),
                Text(
                  '实况',
                  style: TextStyle(
                    color: Color(0xFFDDDDDD),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 检查path是否存在缓存文件
  bool _existFile() {
    if (_targetPath == null) return false;
    final file = File(_targetPath!);
    bool result = file.existsSync();
    return result;
  }

  /// 检查缩略图是否存在缓存文件
  bool _existThumbnailFile() {
    if (widget.data.thumbnailPath == null) return false;
    final file = File(widget.data.thumbnailPath!);
    return file.existsSync();
  }

  Future<String> getDownloadFuture() {
    if (downloadFuture == null) {
      downloadFuture = _downloadFile();
    }
    return downloadFuture!;
  }

  Future<String> _downloadFile() async {
    if (widget.data.asyncPath != null) {
      if (open) await Future.delayed(Duration(milliseconds: 500));
      _targetPath = await widget.data.asyncPath!();
      return 'success';
    }
    if (_targetPath == null || _targetPath!.isEmpty)
      return "No download path specified.";
    if (widget.data.url == null || widget.data.url!.isEmpty)
      return "No download url specified.";
    fileDownloader ??= FileDownloader();
    return await fileDownloader!.download(widget.data.url!, _targetPath!);
  }
}

class ImageLoading extends StatelessWidget {
  final String? path;
  final ImageProvider? provider;
  final String? tag;
  final bool showLoading;

  const ImageLoading({
    Key? key,
    this.path,
    this.provider,
    this.showLoading = true,
    this.tag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final widget = Center(
        child: SizedBox(
      child: Platform.isIOS || Platform.isMacOS
          ? const CupertinoActivityIndicator()
          : const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
            ),
    ));

    Widget? image = null;
    if (provider != null) {
      image = Image(image: provider!, fit: BoxFit.contain);
    } else if (path != null || path!.isNotEmpty) {
      image = Image(
        image: FileImage(File.fromUri(Uri.file(path!))),
        fit: BoxFit.contain,
      );
    }

    return image == null
        ? widget
        : Builder(builder: (context) {
            final child = Align(
              alignment: Alignment.center,
              child: Hero(
                child: Container(
                  width: double.infinity,
                  child: image,
                ),
                tag: tag ?? "",
              ),
            );

            return showLoading
                ? Stack(
                    children: <Widget>[
                      child,
                      widget,
                    ],
                  )
                : child;
          });
  }
}

class ImageError extends StatelessWidget {
  final String? describe;
  final String? msg;

  const ImageError({
    Key? key,
    this.msg,
    this.describe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          Icons.broken_image,
          color: Colors.red,
          size: 30,
        ),
        SizedBox(height: 10),
        Text(
          msg ?? 'Image load failed',
          style: TextStyle(color: Colors.red),
        ),
        SizedBox(height: 15),
        Container(
          width: MediaQuery.of(context).size.width - 100,
          child: Text(
            describe ?? '',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    ));
  }
}
