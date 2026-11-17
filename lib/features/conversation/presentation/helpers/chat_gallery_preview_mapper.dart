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
  if (imagePath != null && File(imagePath).existsSync()) {
    return GalleryPreviewItem(
      imageProvider: FileImage(File(imagePath)),
      saveSource: PreviewSaveFromLocalPath(imagePath),
    );
  }
  final imageUrl = imageMessage.imageUrl ?? '';
  return GalleryPreviewItem(
    imageProvider: CachedNetworkImageProvider(imageUrl),
    saveSource: PreviewSaveFromUrl(imageUrl),
  );
}
