import 'dart:io';

import 'package:all_flutter0709/app/theme/app_system_ui.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 发布页本地图片预览。
class TopicSubmitLocalPreviewPage extends StatefulWidget {
  const TopicSubmitLocalPreviewPage({
    super.key,
    required this.file,
    this.isVideo = false,
  });

  final File file;
  final bool isVideo;

  /// 打开本地图片或视频预览。
  static Future<void> open({
    required BuildContext context,
    required File file,
    bool isVideo = false,
  }) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            TopicSubmitLocalPreviewPage(file: file, isVideo: isVideo),
      ),
    );
  }

  @override
  State<TopicSubmitLocalPreviewPage> createState() =>
      _TopicSubmitLocalPreviewPageState();
}

class _TopicSubmitLocalPreviewPageState
    extends State<TopicSubmitLocalPreviewPage> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _videoController = VideoPlayerController.file(widget.file)
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() {});
          _videoController?.play();
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        systemOverlayStyle: AppSystemUi.overlayStyle,
      ),
      body: Center(
        child: widget.isVideo ? _buildVideo() : Image.file(widget.file),
      ),
    );
  }

  Widget _buildVideo() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return const CircularProgressIndicator(color: Colors.white);
    }
    return GestureDetector(
      onTap: () {
        if (controller.value.isPlaying) {
          controller.pause();
        } else {
          controller.play();
        }
        setState(() {});
      },
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio == 0
            ? 16 / 9
            : controller.value.aspectRatio,
        child: VideoPlayer(controller),
      ),
    );
  }
}
