import 'package:all_flutter0709/features/conversation/presentation/helpers/chat_gallery_preview_mapper.dart';
import 'package:all_flutter0709/features/conversation/presentation/models/chat_item.dart';
import 'package:all_flutter0709/shared/media/open_image_gallery_preview.dart';
import 'package:flutter/material.dart';

/// 聊天图片预览：从当前气泡列表打开全屏预览页。
class ChatImagePreviewHelper {
  const ChatImagePreviewHelper();

  /// 打开图片预览，定位到 [tappedItem] 对应索引。
  void open({
    required BuildContext context,
    required ImageMessage tappedItem,
    required List<ChatItem> items,
  }) {
    final imageMessageList = items.whereType<ImageMessage>().toList(
      growable: false,
    );
    final initialIndex = imageMessageList.indexWhere(
      (item) => item.id == tappedItem.id,
    );
    if (initialIndex < 0) {
      return;
    }

    openImageGalleryPreview(
      context,
      itemList: imageMessageListToGalleryPreviewItemList(imageMessageList),
      initialIndex: initialIndex,
    );
  }
}
