import 'package:flutter/material.dart';

/// 聊天气泡列表滚动（配合 `ListView(reverse: true)`：offset 0 = 视觉底部）。
class ChatScrollHelper {
  ChatScrollHelper(this.scrollController);

  final ScrollController scrollController;

  int _lastItemCount = 0;

  /// 是否贴在底部附近（允许少量偏差）。
  bool get isNearBottom {
    if (!scrollController.hasClients) {
      return true;
    }
    return scrollController.position.pixels <= 48;
  }

  /// 滚到视觉底部；reverse 列表下即为 offset 0，一律 jump，避免发消息时动画抖动。
  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) {
        return;
      }
      final target = scrollController.position.minScrollExtent;
      if ((scrollController.position.pixels - target).abs() < 0.5) {
        return;
      }
      scrollController.jumpTo(target);
    });
  }

  /// 新消息到达：仅在原本贴底时跟到底，避免打断用户上翻历史。
  void scrollIfNewMessages(int itemCount) {
    if (itemCount <= _lastItemCount) {
      _lastItemCount = itemCount;
      return;
    }
    final shouldFollow = isNearBottom || _lastItemCount == 0;
    _lastItemCount = itemCount;
    if (shouldFollow) {
      scrollToBottom();
    }
  }

  /// 强制跟到底（自己发送消息时）。
  void forceScrollToBottom({required int itemCount}) {
    _lastItemCount = itemCount;
    scrollToBottom();
  }
}
