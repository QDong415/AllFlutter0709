import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 动态放大预览中的视频页：支持播放/暂停、拖进度、静音；仅在 [active] 时自动播放。
class TopicPreviewVideoPlayer extends StatefulWidget {
  const TopicPreviewVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.active,
    this.coverUrl,
    this.onCloseTap,
  });

  final String videoUrl;
  final bool active;
  final String? coverUrl;

  /// 单击空白区域关闭预览（控件显隐由内部处理）。
  final VoidCallback? onCloseTap;

  @override
  State<TopicPreviewVideoPlayer> createState() =>
      _TopicPreviewVideoPlayerState();
}

class _TopicPreviewVideoPlayerState extends State<TopicPreviewVideoPlayer> {
  static const _controlsAutoHide = Duration(seconds: 3);

  VideoPlayerController? _controller;
  bool _isInitializing = false;
  String? _errorText;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_initPlayer());
  }

  @override
  void didUpdateWidget(covariant TopicPreviewVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      unawaited(_initPlayer());
      return;
    }
    if (oldWidget.active != widget.active) {
      _syncPlayState();
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _disposePlayer();
    super.dispose();
  }

  Future<void> _initPlayer() async {
    final url = widget.videoUrl.trim();
    if (url.isEmpty) {
      _disposePlayer();
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _errorText = '视频地址无效';
      });
      return;
    }

    _disposePlayer();
    setState(() {
      _isInitializing = true;
      _errorText = null;
      _showControls = true;
    });

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted || _controller != controller) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(false);
      await controller.setVolume(1);
      if (!mounted || _controller != controller) return;
      setState(() {
        _isInitializing = false;
        _errorText = null;
      });
      _syncPlayState();
    } catch (_) {
      await controller.dispose();
      if (_controller == controller) {
        _controller = null;
      }
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _errorText = '视频加载失败';
      });
    }
  }

  void _disposePlayer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = null;
    final controller = _controller;
    _controller = null;
    controller?.dispose();
  }

  void _syncPlayState() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (widget.active) {
      if (!controller.value.isPlaying) {
        unawaited(controller.play());
      }
      _scheduleHideControls();
    } else if (controller.value.isPlaying) {
      unawaited(controller.pause());
      _hideControlsTimer?.cancel();
    }
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    final controller = _controller;
    if (controller == null || !controller.value.isPlaying) {
      return;
    }
    _hideControlsTimer = Timer(_controlsAutoHide, () {
      if (!mounted) return;
      setState(() {
        _showControls = false;
      });
    });
  }

  void _toggleControlsOrClose() {
    if (!_showControls) {
      setState(() {
        _showControls = true;
      });
      _scheduleHideControls();
      return;
    }
    // 控件已显示时再点空白：关闭预览（与图片预览点击关闭一致）。
    widget.onCloseTap?.call();
  }

  void _handlePlayPause() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isPlaying) {
      unawaited(controller.pause());
      _hideControlsTimer?.cancel();
      setState(() {
        _showControls = true;
      });
    } else {
      final finished =
          controller.value.duration > Duration.zero &&
          controller.value.position >= controller.value.duration;
      if (finished) {
        unawaited(controller.seekTo(Duration.zero));
      }
      unawaited(controller.play());
      _scheduleHideControls();
    }
    setState(() {});
  }

  void _handleToggleMute() {
    final controller = _controller;
    if (controller == null) return;
    final muted = controller.value.volume <= 0;
    unawaited(controller.setVolume(muted ? 1 : 0));
    _scheduleHideControls();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller?.value.isInitialized ?? false;

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ready && controller != null)
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio == 0
                    ? 16 / 9
                    : controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            )
          else
            _CoverLayer(
              coverUrl: widget.coverUrl,
              isLoading: _isInitializing,
              errorText: _errorText,
              onRetry: () => unawaited(_initPlayer()),
            ),
          if (ready && controller != null)
            _ControlsOverlay(
              controller: controller,
              showControls: _showControls,
              onBackgroundTap: _toggleControlsOrClose,
              onPlayPause: _handlePlayPause,
              onToggleMute: _handleToggleMute,
              onSeekInteraction: _scheduleHideControls,
            ),
        ],
      ),
    );
  }
}

/// 封面 / 加载 / 错误层。
class _CoverLayer extends StatelessWidget {
  const _CoverLayer({
    required this.coverUrl,
    required this.isLoading,
    required this.errorText,
    required this.onRetry,
  });

  final String? coverUrl;
  final bool isLoading;
  final String? errorText;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final url = coverUrl?.trim() ?? '';
    return Stack(
      fit: StackFit.expand,
      children: [
        if (url.isNotEmpty)
          CachedNetworkImage(imageUrl: url, fit: BoxFit.contain)
        else
          const ColoredBox(color: Colors.black),
        if (isLoading)
          const Center(
            child: CircularProgressIndicator(color: Colors.white70),
          ),
        if (errorText != null)
          Center(
            child: GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x99000000),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$errorText，点击重试',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 播放控件层。
class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({
    required this.controller,
    required this.showControls,
    required this.onBackgroundTap,
    required this.onPlayPause,
    required this.onToggleMute,
    required this.onSeekInteraction,
  });

  final VideoPlayerController controller;
  final bool showControls;
  final VoidCallback onBackgroundTap;
  final VoidCallback onPlayPause;
  final VoidCallback onToggleMute;
  final VoidCallback onSeekInteraction;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final value = controller.value;
        final duration = value.duration;
        final position = value.position;
        final maxMs = duration.inMilliseconds;
        final posMs = position.inMilliseconds.clamp(0, maxMs > 0 ? maxMs : 0);
        final progress = maxMs <= 0 ? 0.0 : posMs / maxMs;

        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBackgroundTap,
              child: const ColoredBox(color: Colors.transparent),
            ),
            if (showControls) ...[
              Center(
                child: IconButton(
                  onPressed: onPlayPause,
                  iconSize: 64,
                  color: Colors.white,
                  icon: Icon(
                    value.isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_filled_rounded,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 8, 16),
                    child: Row(
                      children: [
                        Text(
                          _formatDuration(position),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12,
                              ),
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white38,
                              thumbColor: Colors.white,
                            ),
                            child: Slider(
                              value: progress.clamp(0.0, 1.0),
                              onChanged: maxMs <= 0
                                  ? null
                                  : (next) {
                                      onSeekInteraction();
                                      controller.seekTo(
                                        Duration(
                                          milliseconds: (next * maxMs).round(),
                                        ),
                                      );
                                    },
                            ),
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        IconButton(
                          onPressed: onToggleMute,
                          color: Colors.white,
                          icon: Icon(
                            value.volume <= 0
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds.clamp(0, 99 * 60 + 59);
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
