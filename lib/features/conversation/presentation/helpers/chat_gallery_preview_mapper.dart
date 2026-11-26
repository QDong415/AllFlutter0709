import 'dart:io';

import 'package:all_flutter0709/features/conversation/presentation/models/chat_item.dart';
import 'package:all_flutter0709/shared/media/gallery_preview_item.dart';
import 'package:all_flutter0709/shared/media/preview_save_source.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 将聊天图片消息转为全屏画廊预览项。
List<GalleryPreviewItem> imageMessageListToGalleryPreviewItemList(
  List<ImageMessage> imageMessageList,
) {
  return imageMessageList
      .map((imageMessage) => _toGalleryPreviewItem(imageMessage))
      .toList(growable: false);
}

GalleryPreviewItem _toGalleryPreviewItem(ImageMessage imageMessage) {
  final imagePath = imageMessage.imagePath;
  final ImageProvider<Object> imageProvider;
  final PreviewSaveSource stillSaveSource;
  if (imagePath != null && File(imagePath).existsSync()) {
    imageProvider = FileImage(File(imagePath));
    stillSaveSource = PreviewSaveFromLocalPath(imagePath);
  } else {
    final imageUrl = imageMessage.imageUrl ?? '';
    imageProvider = CachedNetworkImageProvider(imageUrl);
    stillSaveSource = PreviewSaveFromUrl(imageUrl);
  }
  final livePath = imageMessage.liveVideoPath?.trim() ?? '';
  final liveUrl = imageMessage.liveVideoUrl?.trim() ?? '';
  final hasLocalVideo = livePath.isNotEmpty && File(livePath).existsSync();
  if (imageMessage.hasLive && (hasLocalVideo || liveUrl.isNotEmpty)) {
    return GalleryLiveVideoPreviewItem(
      coverImageProvider: imageProvider,
      placeholderImageProvider: imageProvider,
      videoUrl: liveUrl,
      videoPath: hasLocalVideo ? livePath : null,
      saveSource: hasLocalVideo
          ? PreviewSaveFromLocalPath(livePath)
          : PreviewSaveFromUrl(liveUrl),
    );
  }
  return GalleryImagePreviewItem(
    imageProvider: imageProvider,
    placeholderImageProvider: imageProvider,
    saveSource: stillSaveSource,
  );
}
