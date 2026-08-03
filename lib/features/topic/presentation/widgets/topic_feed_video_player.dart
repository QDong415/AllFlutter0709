import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_picture_grid.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_video_preview_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:video_player/video_player.dart';

/// 动态列表内嵌极简视频播放器：无播放/暂停按钮，仅底部细进度条与倒计时。
///
/// 点击后打开放大预览，并与预览页共用同一个 [VideoPlayerController]，进度无缝衔接。
/// 展示尺寸与 [TopicPictureGrid] 单张图片一致。
class TopicFeedVideoPlayer extends StatefulWidget {
  const TopicFeedVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.play,
    this.coverPicture,
    this.resumeNonce = 0,
  });

  final String videoUrl;

  /// 封面图（通常为 pictures[0]），用于占位与尺寸计算。
  final TopicPictureModel? coverPicture;

  /// 是否处于可视区并应自动播放。
  final bool play;

  /// 外部递增时强制重新 [_TopicFeedVideoPlayerState._syncPlayState]。
  final int resumeNonce;

  @override
  State<TopicFeedVideoPlayer> createState() => _TopicFeedVideoPlayerState();
}

class _TopicFeedVideoPlayerState extends State<TopicFeedVideoPlayer> {
  VideoPlayerController? _controller;
  TopicVideoControllerHandoff? _previewHandoff;
  bool _isInitializing = false;
  bool _isOpeningPreview = false;
  String? _errorText;

  /// 用于感知被详情等上层路由盖住 / 恢复（Shell + root 推送场景）。
  bool? _tickersEnabled;

  bool get _isPreviewOpen => _previewHandoff != null;

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
      if (_isPreviewOpen) {
        // 预览占用中不重建 controller，避免打断放大页。
        return;
      }
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

    if (oldWidget.play != widget.play && !_isPreviewOpen) {
      _syncPlayState();
    }

    if (oldWidget.resumeNonce != widget.resumeNonce && !_isPreviewOpen) {
      _syncPlayState();
    }
  }

  @override
  void dispose() {
    final handoff = _previewHandoff;
    if (handoff != null) {
      handoff.listDisposed = true;
      _controller = null;
      _previewHandoff = null;
    } else {
      _disposeController();
    }
    super.dispose();
  }

  Future<void> _ensureInitializedAndSyncPlay() async {
    final url = widget.videoUrl.trim();
    if (url.isEmpty) {
      return;
    }

    final existing = _controller;
    if (existing != null) {
      if (!_isPreviewOpen) {
        _syncPlayState();
      }
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
      if (!_isPreviewOpen) {
        _syncPlayState();
      }
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
    if (!mounted || _isPreviewOpen) return;
    setState(() {});
  }

  void _syncPlayState() {
    if (_isPreviewOpen) return;

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

    // 被上层路由盖住时不续播，避免与详情页播放器抢占，返回后由
    // [_onTickerModeChanged] 再同步。
    final tickersEnabled = _tickersEnabled ?? true;
    if (widget.play && tickersEnabled) {
      if (!controller.value.isPlaying) {
        controller.play();
      }
    } else if (controller.value.isPlaying) {
      controller.pause();
    }
  }

  void _onTickerModeChanged(bool enabled) {
    if (!mounted || _isPreviewOpen) return;
    if (enabled) {
      _syncPlayState();
    } else {
      final controller = _controller;
      if (controller != null &&
          controller.value.isInitialized &&
          controller.value.isPlaying) {
        controller.pause();
      }
    }
  }

  void _disposeController() {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    controller.removeListener(_onControllerTick);
    controller.dispose();
  }

  Future<void> _onTapOpenPreview() async {
    if (_isOpeningPreview || _isPreviewOpen) return;

    final url = widget.videoUrl.trim();
    if (url.isEmpty) return;

    _isOpeningPreview = true;
    try {
      await _ensureInitializedAndSyncPlay();
      final controller = _controller;
      if (!mounted ||
          controller == null ||
          !controller.value.isInitialized) {
        return;
      }

      await _openPreview(controller);
    } finally {
      _isOpeningPreview = false;
    }
  }

  Future<void> _openPreview(VideoPlayerController controller) async {
    controller.removeListener(_onControllerTick);

    final handoff = TopicVideoControllerHandoff(controller);
    _previewHandoff = handoff;

    // 先从列表树卸下 VideoPlayer，再挂到放大页，避免同一 controller 双挂载。
    setState(() {});
    await SchedulerBinding.instance.endOfFrame;

    try {
      await controller.setVolume(1);
    } catch (_) {}

    if (!mounted) {
      handoff.listDisposed = true;
      try {
        await controller.dispose();
      } catch (_) {}
      return;
    }

    await TopicVideoPreviewPage.open(
      context: context,
      handoff: handoff,
      videoUrl: widget.videoUrl,
    );

    _previewHandoff = null;

    if (handoff.listDisposed) {
      _controller = null;
      return;
    }

    if (!mounted) {
      try {
        await controller.dispose();
      } catch (_) {}
      _controller = null;
      return;
    }

    try {
      await controller.setVolume(0);
      await controller.setLooping(true);
    } catch (_) {}
    controller.addListener(_onControllerTick);
    _syncPlayState();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.videoUrl.trim();
    if (url.isEmpty) {
      return const SizedBox.shrink();
    }

    // 依赖 TickerMode：详情盖在 root 上时 shell 子树 tickers 会被关掉并触发重建。
    final tickersEnabled = TickerMode.valuesOf(context).enabled;
    if (_tickersEnabled != tickersEnabled) {
      final previous = _tickersEnabled;
      _tickersEnabled = tickersEnabled;
      if (previous != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onTickerModeChanged(tickersEnabled);
        });
      }
    }

    final coverPicture = widget.coverPicture;
    final controller = _controller;
    final initialized =
        !_isPreviewOpen && (controller?.value.isInitialized ?? false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = TopicPictureGrid.resolveSinglePictureSize(
          width: coverPicture?.width,
          height: coverPicture?.height,
          maxWidth: constraints.maxWidth,
        );

        return Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: _onTapOpenPreview,
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
