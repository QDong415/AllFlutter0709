import 'dart:io';

/// 发布动态时选中的本地图片或视频。
class TopicSubmitMediaModel {
  const TopicSubmitMediaModel({
    required this.file,
    required this.isVideo,
    this.duration,
  });

  final File file;
  final bool isVideo;
  final Duration? duration;

  /// 视频时长展示文案，如 `00:12`。
  String get durationLabel {
    final totalSeconds = duration?.inSeconds ?? 0;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
