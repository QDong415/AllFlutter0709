import 'package:all_flutter0709/features/conversation/presentation/chat_image_preview_page.dart';
import 'package:all_flutter0709/features/conversation/presentation/models/chat_item.dart';
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
    final imageItems = items.whereType<ImageMessage>().toList(growable: false);
    final initialIndex = imageItems.indexOf(tappedItem);
    if (initialIndex < 0) {
      return;
    }

    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (context, animation, secondaryAnimation) {
          return ChatImagePreviewPage(
            images: imageItems,
            initialIndex: initialIndex,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          final scale = Tween<double>(begin: 0.96, end: 1.0).animate(fade);
          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
      ),
    );
  }
}
