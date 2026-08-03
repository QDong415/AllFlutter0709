import 'dart:io';

import 'package:all_flutter0709/app/theme/app_system_ui.dart';
import 'package:dio/dio.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

/// 列表与放大预览之间移交 [VideoPlayerController] 的所有权标记。
class TopicVideoControllerHandoff {
  TopicVideoControllerHandoff(this.controller);

  final VideoPlayerController controller;

  /// 列表侧 Widget 已销毁；预览关闭时需负责 dispose controller。
  bool listDisposed = false;
}

/// 动态视频放大预览页：复用列表已初始化的 controller，进度无缝衔接。
class TopicVideoPreviewPage extends StatefulWidget {
  const TopicVideoPreviewPage({
    super.key,
    required this.handoff,
    required this.videoUrl,
  });

  final TopicVideoControllerHandoff handoff;
  final String videoUrl;

  /// 打开视频放大预览（与图片预览相同的过渡动画）。
  static Future<void> open({
    required BuildContext context,
    required TopicVideoControllerHandoff handoff,
    required String videoUrl,
  }) {
    FocusManager.instance.primaryFocus?.unfocus();
    return Navigator.of(context, rootNavigator: true)
        .push<void>(
          PageRouteBuilder<void>(
            opaque: false,
            transitionDuration: const Duration(milliseconds: 220),
            reverseTransitionDuration: const Duration(milliseconds: 180),
            pageBuilder: (context, animation, secondaryAnimation) {
              return TopicVideoPreviewPage(
                handoff: handoff,
                videoUrl: videoUrl,
              );
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  final fade = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  );
                  final scale = Tween<double>(
                    begin: 0.96,
                    end: 1.0,
                  ).animate(fade);
                  return FadeTransition(
                    opacity: fade,
                    child: ScaleTransition(scale: scale, child: child),
                  );
                },
          ),
        )
        .whenComplete(() {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FocusManager.instance.primaryFocus?.unfocus();
          });
        });
  }

  @override
  State<TopicVideoPreviewPage> createState() => _TopicVideoPreviewPageState();
}

class _TopicVideoPreviewPageState extends State<TopicVideoPreviewPage> {
  final Dio _dio = Dio();
  double _overlayOpacity = 1;

  VideoPlayerController get _controller => widget.handoff.controller;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTick);
    // 进入放大页时保持列表当前的播放/暂停状态，仅打开声音。
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    if (widget.handoff.listDisposed) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTick() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _showActions() async {
    await showModalBottomSheet<void>(
      context: context,
      barrierColor: Colors.transparent,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Center(
                  child: Text(
                    '保存视频',
                    style: TextStyle(color: Color(0xFF111111), fontSize: 16),
                  ),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _saveVideo();
                },
              ),
              const Divider(height: 1, color: Color(0xFFE5E5E5)),
              ListTile(
                title: const Center(
                  child: Text(
                    '取消',
                    style: TextStyle(color: Color(0xFF666666), fontSize: 16),
                  ),
                ),
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveVideo() async {
    final videoUrl = widget.videoUrl.trim();
    if (videoUrl.isEmpty) {
      _showMessage('视频地址无效');
      return;
    }

    File? tempFile;
    try {
      final dir = await getTemporaryDirectory();
      final name = _buildVideoName(videoUrl);
      tempFile = File('${dir.path}/$name');
      await _dio.download(videoUrl, tempFile.path);
      await Gal.putVideo(tempFile.path);
      _showMessage('已保存到相册');
    } catch (e) {
      _showMessage('保存失败: $e');
    } finally {
      try {
        if (tempFile != null && await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
    }
  }

  String _buildVideoName(String videoUrl) {
    final uri = Uri.tryParse(videoUrl);
    final lastSegment = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : null;
    final fileName = (lastSegment == null || lastSegment.isEmpty)
        ? 'topic_${DateTime.now().millisecondsSinceEpoch}.mp4'
        : lastSegment;
    final safe = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    if (safe.contains('.')) return safe;
    return '$safe.mp4';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _togglePlayPause() {
    if (!_controller.value.isInitialized) return;
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      final finished =
          _controller.value.duration > Duration.zero &&
          _controller.value.position >= _controller.value.duration;
      if (finished) {
        _controller.seekTo(Duration.zero);
      }
      _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller.value;
    final initialized = value.isInitialized;

    return FullscreenMediaSystemUi(
      child: DismissiblePage(
        direction: DismissiblePageDismissDirection.vertical,
        backgroundColor: Colors.black,
        startingOpacity: 1,
        dragSensitivity: 0.7,
        minRadius: 0,
        maxRadius: 24,
        onDragUpdate: (details) {
          final nextOpacity = details.opacity.clamp(0.0, 1.0);
          if (_overlayOpacity == nextOpacity) return;
          setState(() {
            _overlayOpacity = nextOpacity;
          });
        },
        onDismissed: () => Navigator.of(context).maybePop(),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _togglePlayPause,
                  onLongPress: _showActions,
                  child: Center(
                    child: initialized
                        ? AspectRatio(
                            aspectRatio: value.aspectRatio == 0
                                ? 16 / 9
                                : value.aspectRatio,
                            child: VideoPlayer(_controller),
                          )
                        : const ColoredBox(color: Colors.black),
                  ),
                ),
              ),
              if (initialized && !value.isPlaying)
                IgnorePointer(
                  child: Center(
                    child: Icon(
                      Icons.play_circle_filled_rounded,
                      size: 72,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              if (initialized)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedOpacity(
                    opacity: _overlayOpacity,
                    duration: const Duration(milliseconds: 120),
                    child: _BottomSeekBar(controller: _controller),
                  ),
                ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 16,
                child: AnimatedOpacity(
                  opacity: _overlayOpacity,
                  duration: const Duration(milliseconds: 120),
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black45,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 底部可拖动进度条。
class _BottomSeekBar extends StatelessWidget {
  const _BottomSeekBar({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    final duration = value.duration;
    final position = value.position;
    final maxMs = duration.inMilliseconds;
    final posMs = position.inMilliseconds.clamp(0, maxMs > 0 ? maxMs : 0);
    final progress = maxMs <= 0 ? 0.0 : posMs / maxMs;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        child: Row(
          children: [
            Text(
              _formatDuration(position),
              style: const TextStyle(color: Colors.white, fontSize: 12),
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
                          controller.seekTo(
                            Duration(milliseconds: (next * maxMs).round()),
                          );
                        },
                ),
              ),
            ),
            Text(
              _formatDuration(duration),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds.clamp(0, 99 * 60 + 59);
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
