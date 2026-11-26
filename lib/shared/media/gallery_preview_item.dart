import 'package:all_flutter0709/shared/media/preview_save_source.dart';
import 'package:flutter/material.dart';

/// 全屏画廊预览的一项：普通图片或 Live 短视频。
sealed class GalleryPreviewItem {
  const GalleryPreviewItem();
}

/// 可缩放的静图。
class GalleryImagePreviewItem extends GalleryPreviewItem {
  const GalleryImagePreviewItem({
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

/// Live 短视频。封面用于占位和 Hero，[videoUrl] 才是播放地址。
class GalleryLiveVideoPreviewItem extends GalleryPreviewItem {
  const GalleryLiveVideoPreviewItem({
    required this.coverImageProvider,
    required this.videoUrl,
    required this.saveSource,
    this.videoPath,
    this.placeholderImageProvider,
    this.heroTag,
  });

  final ImageProvider<Object> coverImageProvider;
  final String videoUrl;

  /// 本地短视频。有文件时优先于 [videoUrl] 播放。
  final String? videoPath;
  final PreviewSaveSource saveSource;

  /// 封面未画出时的缩略图。
  final ImageProvider<Object>? placeholderImageProvider;

  /// 非空时把封面挂上 Hero，和九宫格静图对接。
  final String? heroTag;
}
