import 'package:all_flutter0709/shared/media/preview_save_source.dart';
import 'package:flutter/material.dart';

/// 全屏画廊预览的单项：展示图源与保存来源解耦，便于本地/网络共用一页。
class GalleryPreviewItem {
  const GalleryPreviewItem({
    required this.imageProvider,
    required this.saveSource,
    this.placeholderImageProvider,
    this.heroTag,
  });

  final ImageProvider<Object> imageProvider;
  final PreviewSaveSource saveSource;

  /// 原图加载期间展示的列表缩略图；为空时保持黑色背景。
  final ImageProvider<Object>? placeholderImageProvider;

  /// 非空时启用图片预览 Hero 过渡。
  final String? heroTag;
}
