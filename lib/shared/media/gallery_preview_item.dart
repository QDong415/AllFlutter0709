import 'package:all_flutter0709/shared/media/preview_save_source.dart';
import 'package:flutter/material.dart';

/// 全屏画廊预览的单项：展示图源与保存来源解耦，便于本地/网络共用一页。
class GalleryPreviewItem {
  const GalleryPreviewItem({
    required this.imageProvider,
    required this.saveSource,
    this.heroTag,
  });

  final ImageProvider<Object> imageProvider;
  final PreviewSaveSource saveSource;

  /// 非空时启用 [PhotoView] Hero 过渡。
  final String? heroTag;
}
