import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_preview/preview.dart';
import 'package:image_preview/preview_data.dart';
import 'package:image_preview/src/preview_gallery.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:video_player/video_player.dart';

typedef OnPlayStateListener(bool isPlaying);

class VideoPreview extends StatefulWidget {
  const VideoPreview({
    super.key,
    required this.data,
    required this.heroTag,
    required this.open,
    this.playIconSize = 60,
    this.onLongPressHandler,
    this.onPlayStateListener,
    this.onPlayControllerListener,
  });

  final VideoData data;
  final String heroTag;
  final bool open;
  final double playIconSize;
  final OnLongPressHandler? onLongPressHandler;
  final OnPlayStateListener? onPlayStateListener;
  final OnPlayControllerListener? onPlayControllerListener;

  @override
  State<StatefulWidget> createState() => VideoPreviewState();
}

class VideoPreviewState extends State<VideoPreview> {
  var _open = false;
  VideoPlayerController? _controller;
  double _position = 0;
  var _userSlider = false; // 用户在触发进度条
  var _showTime = false;
  var _playing = false;
  var _startPop = false;

  @override
  void initState() {
    _open = widget.open;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      _open = false;
    }
    if (widget.data.coverUrl != null && widget.data.coverUrl!.isNotEmpty) {}
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      if (_open) {
        await Future.delayed(Duration(milliseconds: 500));
        _preparePlay();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant VideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (_) {
        setState(() {
          _startPop = true;
        });
      },
      canPop: true,
      // onPopInvokedWithResult: (_, __) {
      //   setState(() {
      //     _startPop = true;
      //   });
      // },
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: _controller != null && _controller!.value.isPlaying
            ? () {
                if (_controller != null && _controller!.value.isPlaying) {
                  _controller!.pause();
                  setState(() {
                    _showTime = true;
                  });
                }
              }
            : null,
        onLongPress: () {
          if (widget.onLongPressHandler != null) {
            widget.onLongPressHandler!(
                context,
                PreviewData(
                  type: Type.video,
                  video: widget.data,
                ));
          }
        },
        child: Stack(
          children: [
            if (_controller != null && _controller!.value.isInitialized)
              Align(
                alignment: Alignment.center,
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: Hero(
                    child: VideoPlayer(_controller!),
                    tag: widget.heroTag,
                  ),
                ),
              ),
            if ((_controller == null || !_controller!.value.isInitialized || _controller!.value.position.inSeconds == 0) &&
                (kIsWeb || widget.data.coverData != null || _existCoverFile()))
              Align(
                alignment: Alignment.center,
                child: Hero(
                  child: Container(
                    width: double.infinity,
                    child: kIsWeb
                        ? Image(
                            image: NetworkImage(widget.data.coverUrl ?? ''),
                            fit: BoxFit.contain,
                          )
                        : widget.data.coverData != null
                            ? Image.memory(widget.data.coverData!,
                                fit: BoxFit.contain)
                            : Image(
                                image: FileImage(File.fromUri(
                                    Uri.file(widget.data.coverPath!))),
                                fit: BoxFit.contain,
                              ),
                  ),
                  tag: widget.heroTag,
                ),
              ),
            if (_controller != null &&
                (!_controller!.value.isInitialized ||
                    _controller!.value.isBuffering))
              Align(
                alignment: Alignment.center,
                child: !kIsWeb && (Platform.isIOS || Platform.isMacOS)
                    ? const CupertinoActivityIndicator()
                    : const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
              ),
            if (_controller != null && _controller!.value.isInitialized)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      16, 0, 16, MediaQuery.of(context).padding.bottom + 8),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 20,
                      maxWidth: 600,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width:
                              60 * MediaQuery.of(context).textScaler.scale(1),
                          child: _showTime
                              ? Center(
                                  child: Text(
                                    _formatDuration(
                                        Duration(seconds: _position.toInt())),
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 11),
                                  ),
                                )
                              : null,
                        ),
                        Expanded(
                          child: Container(
                            // color: Colors.red,
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                overlayShape: SliderComponentShape.noThumb,
                                trackHeight: 1,
                                inactiveTrackColor: Colors.grey.shade800,
                                activeTrackColor: Colors.grey.shade600,
                                thumbColor: Colors.grey.shade600,
                                thumbShape: RoundSliderThumbShape(
                                    enabledThumbRadius: 5),
                              ),
                              child: Slider(
                                value: _position,
                                min: 0,
                                max: _controller!.value.duration.inSeconds
                                    .toDouble(),
                                onChanged: (value) {
                                  debugPrint('onChanged: $value');
                                  setState(() {
                                    _position = value;
                                  });
                                },
                                onChangeStart: (value) {
                                  // debugPrint('onChangeStart: $value');
                                  _userSlider = true;
                                  setState(() {
                                    _showTime = true;
                                  });
                                },
                                onChangeEnd: (value) {
                                  debugPrint('onChangeEnd: $value');
                                  _userSlider = false;
                                  // seek
                                  _controller?.seekTo(
                                      Duration(seconds: _position.toInt()));
                                  if (_controller!.value.isPlaying) {
                                    setState(() {
                                      _showTime = false;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width:
                              60 * MediaQuery.of(context).textScaler.scale(1),
                          child: _showTime
                              ? Center(
                                  child: Text(
                                    _formatDuration(
                                        _controller!.value.duration),
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 11),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if ((_controller == null && !_open) ||
                (_controller != null &&
                    !_controller!.value.isPlaying &&
                    !_controller!.value.isBuffering &&
                    _controller!.value.isInitialized))
              GestureDetector(
                onTap: () {
                  if (_controller == null) {
                    _preparePlay();
                    setState(() {});
                    return;
                  }
                  if (!_controller!.value.isPlaying) {
                    _controller!.play();
                    setState(() {
                      _showTime = false;
                    });
                  }
                },
                child: Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: buildPlayIconWidget(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _preparePlay() {
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
      _launchURL(widget.data.url!);
      return;
    }

    if (_controller == null) {
      debugPrint('play:${widget.data.url}');
      _playing = false;
      if (widget.data.url!.startsWith("http")) {
        _controller =
            VideoPlayerController.networkUrl(Uri.parse(widget.data.url!))
              ..initialize().then((_) async {
                await _controller?.play();
                _controllerListener();
              });
      } else {
        _controller = VideoPlayerController.file(File(widget.data.url!))
          ..initialize().then((_) async {
            await _controller?.play();
            _controllerListener();
          });
      }
      if (widget.onPlayControllerListener != null) {
        widget.onPlayControllerListener!(_controller!);
      }
    }
  }

  void _controllerListener() {
    _controller!.addListener(() {
      if (!_userSlider) {
        setState(() {
          _position = _controller!.value.position.inSeconds.toDouble();
        });
      }
      if (_controller!.value.hasError) {
        debugPrint(
            'error: ${_controller!.value.errorDescription ?? 'Unknown error'}');
      }
      if (_controller!.value.isPlaying != _playing) {
        _playing = _controller!.value.isPlaying;
        debugPrint('_playing ${_playing}');
        if (widget.onPlayStateListener != null) {
          widget.onPlayStateListener!(_playing);
        }
      }
    });
  }

  /// 检查封面是否存在缓存文件
  bool _existCoverFile() {
    if (widget.data.coverPath == null) return false;
    final file = File(widget.data.coverPath!);
    return file.existsSync();
  }

  Widget buildPlayIconWidget() {
    if (_startPop) return SizedBox();
    return Center(
      child: Opacity(
        opacity: 0.5,
        child: Icon(
          Icons.play_circle_outline,
          color: Color(0xFFDDDDDD),
          size: widget.playIconSize,
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  String hours = twoDigits(duration.inHours);
  String minutes = twoDigits(duration.inMinutes.remainder(60));
  String seconds = twoDigits(duration.inSeconds.remainder(60));

  if (duration.inHours > 0) {
    return '$hours:$minutes:$seconds';
  } else {
    return '$minutes:$seconds';
  }
}

Future<void> _launchURL(String url) async {
  await launchUrlString(
    url,
    mode: LaunchMode.externalApplication,
  );
}
