import 'dart:io';

import 'package:all_flutter0709/app/theme/app_system_ui.dart';
import 'package:dio/dio.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:all_flutter0709/core/push/chat_push_log.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';

/// 列表与放大预览之间移交 [VideoPlayerController] 的所有权标记。
class TopicVideoControllerHandoff {
  TopicVideoControllerHandoff(this.controller);

  final VideoPlayerController controller;

  /// 列表侧 Widget 已销毁；预览关闭时需负责 dispose controller。
  bool listDisposed = false;
}

/// 视频放大预览页。
///
/// 动态列表传入已在播的 [handoff]，进度接着播。没传时用 [filePath] 或 [videoUrl] 自己创建播放器。
class TopicVideoPreviewPage extends StatefulWidget {
  const TopicVideoPreviewPage({
    super.key,
    this.handoff,
    this.videoUrl = '',
    this.filePath,
  });

  final TopicVideoControllerHandoff? handoff;

  /// 远端地址。自己创建播放器时，没有本地文件就播这个；长按保存也用它下载。
  final String videoUrl;

  /// 本地文件。有的话优先于 [videoUrl] 播放，保存时直接写入相册。
  final String? filePath;

  /// 打开视频放大预览（与图片预览相同的过渡动画）。
  static Future<void> open({
    required BuildContext context,
    TopicVideoControllerHandoff? handoff,
    String videoUrl = '',
    String? filePath,
  }) {
    final path = filePath?.trim() ?? '';
    final url = videoUrl.trim();
    if (handoff == null && path.isEmpty && url.isEmpty) {
      ChatVideoLog.d('open 跳过：handoff/filePath/videoUrl 均为空');
      return Future<void>.value();
    }
    ChatVideoLog.d(
      'open handoff=${handoff != null} filePath=$path '
      'videoUrl=${url.isEmpty ? "(空)" : url}',
    );
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
                videoUrl: url,
                filePath: path.isEmpty ? null : path,
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
  VideoPlayerController? _ownedController;
  double _overlayOpacity = 1;
  var _failed = false;

  VideoPlayerController? get _controller =>
      widget.handoff?.controller ?? _ownedController;

  bool get _ownsController => widget.handoff == null;

  @override
  void initState() {
    super.initState();
    final handed = widget.handoff?.controller;
    if (handed != null) {
      ChatVideoLog.d(
        '预览复用 handoff listDisposed=${widget.handoff?.listDisposed} '
        'initialized=${handed.value.isInitialized}',
      );
      handed.addListener(_onTick);
      return;
    }
    _startOwned();
  }

  Future<void> _startOwned() async {
    final path = widget.filePath?.trim() ?? '';
    final url = widget.videoUrl.trim();
    final pathExists = path.isNotEmpty && File(path).existsSync();
    final VideoPlayerController controller;
    if (pathExists) {
      ChatVideoLog.d('自建播放器 source=file path=$path');
      controller = VideoPlayerController.file(File(path));
    } else if (url.isNotEmpty) {
      ChatVideoLog.d(
        '自建播放器 source=network url=$url '
        'filePath=${path.isEmpty ? "(空)" : "$path(不存在)"}',
      );
      controller = VideoPlayerController.networkUrl(Uri.parse(url));
    } else {
      ChatVideoLog.d(
        '自建播放器无可用源 filePath=$path fileExists=$pathExists videoUrl=(空)',
      );
      if (mounted) {
        setState(() => _failed = true);
      }
      return;
    }
    _ownedController = controller;
    controller.addListener(_onTick);
    try {
      ChatVideoLog.d('开始 initialize...');
      await controller.initialize();
      if (!mounted) {
        ChatVideoLog.d('initialize 完成但页面已卸载');
        return;
      }
      ChatVideoLog.d(
        'initialize 成功 duration=${controller.value.duration.inMilliseconds}ms '
        'size=${controller.value.size.width.toInt()}x'
        '${controller.value.size.height.toInt()} '
        'aspect=${controller.value.aspectRatio}',
      );
      await controller.play();
      ChatVideoLog.d('play 已调用 isPlaying=${controller.value.isPlaying}');
      if (mounted) {
        setState(() {});
      }
    } catch (error, stackTrace) {
      ChatVideoLog.d('initialize/play 失败: $error');
      ChatVideoLog.d('$stackTrace');
      if (controller.value.hasError) {
        ChatVideoLog.d(
          '播放器 errorDescription=${controller.value.errorDescription}',
        );
      }
      controller.removeListener(_onTick);
      try {
        await controller.dispose();
      } catch (_) {}
      if (_ownedController == controller) {
        _ownedController = null;
      }
      if (mounted) {
        setState(() => _failed = true);
      }
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    controller?.removeListener(_onTick);
    if (_ownsController) {
      controller?.dispose();
    } else if (widget.handoff?.listDisposed == true) {
      controller?.dispose();
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
    final localPath = widget.filePath?.trim() ?? '';
    if (localPath.isNotEmpty && File(localPath).existsSync()) {
      try {
        await Gal.putVideo(localPath);
        _showMessage('已保存到相册');
      } catch (e) {
        _showMessage('保存失败: $e');
      }
      return;
    }

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
    AppToast.show(context, message);
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      final finished =
          controller.value.duration > Duration.zero &&
          controller.value.position >= controller.value.duration;
      if (finished) {
        controller.seekTo(Duration.zero);
      }
      controller.play();
    }
  }

  Widget _buildVideo(VideoPlayerController? controller, VideoPlayerValue? value) {
    if (_failed) {
      return const Text(
        '视频无法播放',
        style: TextStyle(color: Colors.white70, fontSize: 15),
      );
    }
    if (controller != null && value != null && value.isInitialized) {
      return AspectRatio(
        aspectRatio: value.aspectRatio == 0 ? 16 / 9 : value.aspectRatio,
        child: VideoPlayer(controller),
      );
    }
    return const CircularProgressIndicator(color: Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final value = controller?.value;
    final initialized = value != null && value.isInitialized;

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
                  child: Center(child: _buildVideo(controller, value)),
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
              if (controller != null && initialized)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedOpacity(
                    opacity: _overlayOpacity,
                    duration: const Duration(milliseconds: 120),
                    child: _BottomSeekBar(controller: controller),
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

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0.22),
            Colors.black.withValues(alpha: 0.38),
          ],
          stops: const [0, 0.5, 1],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
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
