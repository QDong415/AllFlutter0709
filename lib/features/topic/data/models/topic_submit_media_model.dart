import 'dart:io';

import 'package:wechat_assets_picker/wechat_assets_picker.dart';

/// 发布动态时选中的本地图片或视频。
class TopicSubmitMediaModel {
  const TopicSubmitMediaModel({
    required this.file,
    required this.isVideo,
    this.duration,
    this.asset,
  });

  final File file;
  final bool isVideo;
  final Duration? duration;

  /// 相册原资源。视频封面用它取缩略图，对齐 Android `Glide.load(LocalMedia)`。
  final AssetEntity? asset;

  /// 视频时长展示文案，如 `00:12`。
  String get durationLabel {
    final totalSeconds = duration?.inSeconds ?? 0;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
