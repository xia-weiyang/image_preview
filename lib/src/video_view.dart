import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_preview/preview.dart';
import 'package:image_preview/preview_data.dart';
import 'package:image_preview/src/preview_gallery.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
    this.onPlayError,
    this.extraBottomPadding = 0,
  });

  final VideoData data;
  final String heroTag;
  final bool open;
  final double playIconSize;
  final OnLongPressHandler? onLongPressHandler;
  final OnPlayStateListener? onPlayStateListener;
  final OnPlayControllerListener? onPlayControllerListener;
  final OnPlayError? onPlayError;
  final double extraBottomPadding;

  @override
  State<StatefulWidget> createState() => VideoPreviewState();
}

class VideoPreviewState extends State<VideoPreview> {
  var _open = false;
  VideoPlayerController? _controller;
  VoidCallback? listener;
  double _position = 0;
  var _userSlider = false; // 用户在触发进度条
  var _showTime = false;
  var _playing = false;
  var _startPop = false;
  var _buffering = true;
  var _playPrepared = false;
  var _paused = false;

  @override
  void initState() {
    _open = widget.open;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      _open = false;
    }
    if (widget.data.coverUrl != null && widget.data.coverUrl!.isNotEmpty) {}
    super.initState();
    WakelockPlus.enable();
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
    if (listener != null) {
      _controller?.removeListener(listener!);
    }
    _controller?.dispose();
    super.dispose();
    WakelockPlus.disable();
  }

  @override
  void didUpdateWidget(covariant VideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (_, __) {
        setState(() {
          _startPop = true;
        });
      },
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: _playPrepared && !_paused
            ? () {
                if (_playing) {
                  _controller!.pause();
                  setState(() {
                    _showTime = true;
                    _paused = true;
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
            if (_playPrepared)
              Align(
                alignment: Alignment.center,
                child: Builder(builder: (context) {
                  var rotationCorrection = 0;
                  try {
                    rotationCorrection = _controller!.value.rotationCorrection;
                  } catch (e) {}
                  var aspectRatio = _controller!.value.aspectRatio;
                  if (rotationCorrection == 90 || rotationCorrection == 270) {
                    aspectRatio = 1 / aspectRatio;
                  }
                  return AspectRatio(
                    aspectRatio: aspectRatio,
                    child: Hero(
                      child: VideoPlayer(_controller!),
                      tag: widget.heroTag,
                    ),
                  );
                }),
              ),
            if (!_playPrepared && (kIsWeb || widget.data.coverProvide != null || _existCoverFile()))
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
                        : widget.data.coverProvide != null
                            ? Image(image: widget.data.coverProvide!, fit: BoxFit.contain)
                            : Image(
                                image: FileImage(File.fromUri(Uri.file(widget.data.coverPath!))),
                                fit: BoxFit.contain,
                              ),
                  ),
                  tag: widget.heroTag,
                ),
              ),
            if (_buffering && !_playing && !_paused)
              Align(
                alignment: Alignment.center,
                child: !kIsWeb && (Platform.isIOS || Platform.isMacOS)
                    ? const CupertinoActivityIndicator()
                    : const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
              ),
            if (_playPrepared)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      16, 0, 16, MediaQuery.of(context).padding.bottom + 8 + widget.extraBottomPadding),
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
                          width: 60 * MediaQuery.of(context).textScaler.scale(1),
                          child: _showTime
                              ? Center(
                                  child: Text(
                                    _formatDuration(Duration(milliseconds: _position.toInt())),
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
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
                                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
                              ),
                              child: Slider(
                                value: _position,
                                min: 0,
                                max: _controller!.value.duration.inMilliseconds.toDouble(),
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
                                  _controller?.seekTo(Duration(milliseconds: _position.toInt()));
                                  if (_playing) {
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
                          width: 60 * MediaQuery.of(context).textScaler.scale(1),
                          child: _showTime
                              ? Center(
                                  child: Text(
                                    _formatDuration(_controller!.value.duration),
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (!_open || _paused)
              GestureDetector(
                onTap: () async {
                  if (_controller == null) {
                    _preparePlay();
                    setState(() {});
                    return;
                  }
                  if (!_playing) {
                    await _controller!.play();
                    setState(() {
                      _showTime = false;
                      _paused = false;
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

  void _preparePlay() async {
    var playUrl = widget.data.url;
    if ((playUrl == null || playUrl.isEmpty) && widget.data.asyncPath != null) {
      playUrl = await widget.data.asyncPath!();
    }

    if (playUrl == null || playUrl.isEmpty) {
      debugPrint('playUrl is null');
    }

    if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
      _launchURL(playUrl!);
      return;
    }

    if (_controller == null) {
      debugPrint('play:${playUrl!}');
      _playing = false;
      if (playUrl.startsWith("http")) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(playUrl))
          ..initialize().then((_) async {
            setState(() {
              _playPrepared = true;
            });
            debugPrint('_playPrepared: $_playPrepared');
            await _controller?.setLooping(true);
            await _controller?.play();
            _controllerListener();
          });
      } else {
        _controller = VideoPlayerController.file(File(playUrl))
          ..initialize().then((_) async {
            setState(() {
              _playPrepared = true;
            });
            debugPrint('_playPrepared: $_playPrepared');
            await _controller?.setLooping(true);
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
    if (listener != null) {
      _controller!.removeListener(listener!);
    }
    _controller!.addListener(listener = () {
      if (!_userSlider) {
        setState(() {
          _position = _controller!.value.position.inMilliseconds.toDouble();
        });
      }
      if (_controller!.value.hasError) {
        final error = _controller!.value.errorDescription ?? 'Unknown error';
        debugPrint('error: $error');
        if (widget.onPlayError != null) {
          widget.onPlayError!(error);
        }
      }
      if (_controller!.value.isPlaying != _playing) {
        setState(() {
          _playing = _controller!.value.isPlaying;
        });
        debugPrint('_playing: ${_playing}');
        if (widget.onPlayStateListener != null) {
          widget.onPlayStateListener!(_playing);
        }
      }
      if (_controller!.value.isBuffering != _buffering) {
        setState(() {
          _buffering = _controller!.value.isBuffering;
        });
        debugPrint('_buffering: ${_buffering}');
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
