import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_picture_grid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 动态列表内嵌极简视频播放器：无播放/暂停按钮，仅底部细进度条与倒计时。
///
/// 展示尺寸与 [TopicPictureGrid] 单张图片一致。
class TopicFeedVideoPlayer extends StatefulWidget {
  const TopicFeedVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.play,
    this.coverPicture,
  });

  final String videoUrl;

  /// 封面图（通常为 pictures[0]），用于占位与尺寸计算。
  final TopicPictureModel? coverPicture;

  /// 是否处于可视区并应自动播放。
  final bool play;

  @override
  State<TopicFeedVideoPlayer> createState() => _TopicFeedVideoPlayerState();
}

class _TopicFeedVideoPlayerState extends State<TopicFeedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitializing = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    if (widget.play) {
      _ensureInitializedAndSyncPlay();
    }
  }

  @override
  void didUpdateWidget(covariant TopicFeedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      if (widget.play) {
        _ensureInitializedAndSyncPlay();
      } else if (mounted) {
        setState(() {
          _errorText = null;
          _isInitializing = false;
        });
      }
      return;
    }

    if (oldWidget.play != widget.play) {
      _syncPlayState();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  Future<void> _ensureInitializedAndSyncPlay() async {
    final url = widget.videoUrl.trim();
    if (url.isEmpty) {
      return;
    }

    final existing = _controller;
    if (existing != null) {
      _syncPlayState();
      return;
    }

    if (_isInitializing) {
      return;
    }

    setState(() {
      _isInitializing = true;
      _errorText = null;
    });

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted || _controller != controller) {
        await controller.dispose();
        return;
      }

      await controller.setLooping(true);
      await controller.setVolume(0);
      controller.addListener(_onControllerTick);

      if (!mounted || _controller != controller) {
        return;
      }

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

  void _onControllerTick() {
    if (!mounted) return;
    setState(() {});
  }

  void _syncPlayState() {
    final controller = _controller;
    if (controller == null) {
      if (widget.play) {
        _ensureInitializedAndSyncPlay();
      }
      return;
    }

    if (!controller.value.isInitialized) {
      return;
    }

    if (widget.play) {
      if (!controller.value.isPlaying) {
        controller.play();
      }
    } else if (controller.value.isPlaying) {
      controller.pause();
    }
  }

  void _disposeController() {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    controller.removeListener(_onControllerTick);
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.videoUrl.trim();
    if (url.isEmpty) {
      return const SizedBox.shrink();
    }

    final coverPicture = widget.coverPicture;
    final controller = _controller;
    final initialized = controller?.value.isInitialized ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = TopicPictureGrid.resolveSinglePictureSize(
          width: coverPicture?.width,
          height: coverPicture?.height,
          maxWidth: constraints.maxWidth,
        );

        return Align(
          alignment: Alignment.centerLeft,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TopicPictureGrid.radius),
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: ColoredBox(
                color: const Color(0xFF111111),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (initialized && controller != null)
                      FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: controller.value.size.width,
                          height: controller.value.size.height,
                          child: VideoPlayer(controller),
                        ),
                      )
                    else
                      _CoverLayer(coverPicture: coverPicture),
                    if (_isInitializing)
                      const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    if (_errorText != null)
                      Center(
                        child: Text(
                          _errorText!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    if (initialized && controller != null)
                      _ProgressOverlay(controller: controller),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 封面占位层。
class _CoverLayer extends StatelessWidget {
  const _CoverLayer({required this.coverPicture});

  final TopicPictureModel? coverPicture;

  @override
  Widget build(BuildContext context) {
    final url = coverPicture?.thumbnailUrl.trim() ?? '';
    if (url.isEmpty) {
      return const ColoredBox(color: Color(0xFF222222));
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      errorWidget: (_, _, _) => const ColoredBox(color: Color(0xFF222222)),
    );
  }
}

/// 底部细进度条 + 右下角倒计时。
class _ProgressOverlay extends StatelessWidget {
  const _ProgressOverlay({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    final duration = value.duration;
    final position = value.position;
    final totalMs = duration.inMilliseconds;
    final progress = totalMs <= 0
        ? 0.0
        : (position.inMilliseconds / totalMs).clamp(0.0, 1.0);
    final remaining = duration > position
        ? duration - position
        : Duration.zero;

    return Stack(
      children: [
        Positioned(
          right: 8,
          bottom: 8,
          child: Text(
            _formatCountdown(remaining),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(color: Color(0x80000000), blurRadius: 2),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SizedBox(
            height: 2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0x66FFFFFF)),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: const ColoredBox(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatCountdown(Duration remaining) {
    final totalSeconds = remaining.inSeconds.clamp(0, 99 * 60 + 59);
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
