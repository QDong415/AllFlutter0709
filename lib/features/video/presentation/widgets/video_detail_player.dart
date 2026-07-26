import 'dart:async';

import 'package:all_flutter0709/features/video/presentation/widgets/video_detail_player_controls.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 视频详情页播放器：自管单击显隐控件 / 双击点赞，避免触发 Chewie 默认遮罩
class VideoDetailPlayer extends StatefulWidget {
  const VideoDetailPlayer({
    super.key,
    required this.videoUrl,
    required this.coverUrl,
    required this.height,
    required this.onDoubleTap,
  });

  final String? videoUrl;
  final String? coverUrl;
  final double height;
  final VoidCallback onDoubleTap;

  @override
  State<VideoDetailPlayer> createState() => _VideoDetailPlayerState();
}

class _VideoDetailPlayerState extends State<VideoDetailPlayer>
    with SingleTickerProviderStateMixin {
  static const _controlsAutoHide = Duration(seconds: 3);

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitializing = false;
  String? _errorText;
  bool _showControls = false;
  bool _showDoubleTapHeart = false;
  Timer? _hideControlsTimer;

  late final AnimationController _heartController;
  late final Animation<double> _heartScale;
  late final Animation<double> _heartOpacity;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
    ]).animate(_heartController);
    _heartOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 40),
    ]).animate(_heartController);
    _heartController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _showDoubleTapHeart = false;
        });
      }
    });
    unawaited(_initPlayer());
  }

  @override
  void didUpdateWidget(covariant VideoDetailPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      unawaited(_initPlayer());
    }
  }

  @override
  void deactivate() {
    _videoController?.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _heartController.dispose();
    _disposePlayer();
    super.dispose();
  }

  Future<void> _initPlayer() async {
    final url = widget.videoUrl?.trim() ?? '';
    if (url.isEmpty) {
      _disposePlayer();
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _errorText = '视频地址无效';
        _showControls = false;
      });
      return;
    }

    _disposePlayer();
    setState(() {
      _isInitializing = true;
      _errorText = null;
      _showControls = false;
    });

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController = controller;

    try {
      await controller.initialize();
      if (!mounted || _videoController != controller) {
        await controller.dispose();
        return;
      }

      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        allowFullScreen: false,
        allowMuting: true,
        showControls: false,
        showControlsOnInitialize: false,
        aspectRatio: controller.value.aspectRatio == 0
            ? null
            : controller.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return _ErrorCover(
            coverUrl: widget.coverUrl,
            message: '加载失败,点击重试',
            onRetry: () {
              unawaited(_initPlayer());
            },
          );
        },
      );
      _chewieController = chewie;
      setState(() {
        _isInitializing = false;
        _errorText = null;
      });
    } catch (_) {
      await controller.dispose();
      if (_videoController == controller) {
        _videoController = null;
      }
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _errorText = '加载失败,点击重试';
      });
    }
  }

  void _disposePlayer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = null;
    _chewieController?.dispose();
    _chewieController = null;
    _videoController?.dispose();
    _videoController = null;
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    final videoController = _videoController;
    if (videoController == null || !videoController.value.isPlaying) {
      return;
    }
    _hideControlsTimer = Timer(_controlsAutoHide, () {
      if (!mounted) return;
      setState(() {
        _showControls = false;
      });
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _scheduleHideControls();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _handleDoubleTapLike() {
    _hideControlsTimer?.cancel();
    if (_showControls) {
      setState(() {
        _showControls = false;
      });
    }
    widget.onDoubleTap();
    setState(() {
      _showDoubleTapHeart = true;
    });
    _heartController.forward(from: 0);
  }

  void _handlePlayPause() {
    final videoController = _videoController;
    if (videoController == null) return;

    if (videoController.value.isPlaying) {
      videoController.pause();
      _hideControlsTimer?.cancel();
    } else {
      final finished =
          videoController.value.duration > Duration.zero &&
          videoController.value.position >= videoController.value.duration;
      if (finished) {
        unawaited(videoController.seekTo(Duration.zero));
      }
      unawaited(videoController.play());
      _scheduleHideControls();
    }
    setState(() {});
  }

  void _handleToggleMute() {
    final videoController = _videoController;
    if (videoController == null) return;
    final muted = videoController.value.volume <= 0;
    unawaited(videoController.setVolume(muted ? 1 : 0));
    _scheduleHideControls();
  }

  @override
  Widget build(BuildContext context) {
    final chewie = _chewieController;
    final videoController = _videoController;
    final ready =
        chewie != null && (videoController?.value.isInitialized ?? false);

    return ColoredBox(
      color: Colors.black,
      child: SizedBox(
        width: double.infinity,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (ready)
              Chewie(controller: chewie)
            else if (_errorText != null)
              _ErrorCover(
                coverUrl: widget.coverUrl,
                message: _errorText!,
                onRetry: () {
                  unawaited(_initPlayer());
                },
              )
            else
              _LoadingCover(
                coverUrl: widget.coverUrl,
                isLoading: _isInitializing,
              ),
            if (ready && !_showControls)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleControls,
                onDoubleTap: _handleDoubleTapLike,
              ),
            if (ready && _showControls && videoController != null)
              VideoDetailPlayerControls(
                controller: videoController,
                onBackgroundTap: _toggleControls,
                onBackgroundDoubleTap: _handleDoubleTapLike,
                onPlayPause: _handlePlayPause,
                onToggleMute: _handleToggleMute,
              ),
            if (_showDoubleTapHeart)
              IgnorePointer(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _heartController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _heartOpacity.value,
                        child: Transform.scale(
                          scale: _heartScale.value,
                          child: child,
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 88,
                      color: Color(0xE6F46533),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCover extends StatelessWidget {
  const _LoadingCover({required this.coverUrl, required this.isLoading});

  final String? coverUrl;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (coverUrl != null && coverUrl!.isNotEmpty)
          CachedNetworkImage(imageUrl: coverUrl!, fit: BoxFit.cover)
        else
          const ColoredBox(color: Colors.black),
        if (isLoading)
          const Center(
            child: CircularProgressIndicator(color: Colors.white70),
          ),
      ],
    );
  }
}

class _ErrorCover extends StatelessWidget {
  const _ErrorCover({
    required this.coverUrl,
    required this.message,
    required this.onRetry,
  });

  final String? coverUrl;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (coverUrl != null && coverUrl!.isNotEmpty)
          CachedNetworkImage(imageUrl: coverUrl!, fit: BoxFit.cover)
        else
          const ColoredBox(color: Colors.black),
        ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
        Center(
          child: GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x99000000),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
