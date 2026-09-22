import 'package:all_flutter0709/features/conversation/presentation/models/chat_item.dart';
import 'package:flutter/material.dart';

/// 气泡长按信息：消息身份、按压点、气泡屏幕矩形（给菜单定位）。
class ChatBubbleLongPressDetails {
  const ChatBubbleLongPressDetails({
    required this.item,
    required this.globalPosition,
    required this.bubbleRect,
  });

  final MessageItem item;
  final Offset globalPosition;
  final Rect bubbleRect;
}

/// 气泡交互回调。页面只接这一组，避免按消息类型拆散点按 / 长按。
class ChatMessageActions {
  const ChatMessageActions({
    this.onAvatarTap,
    this.onMessageTap,
    this.onMessageLongPress,
  });

  static const empty = ChatMessageActions();

  final ValueChanged<MessageItem>? onAvatarTap;
  final ValueChanged<MessageItem>? onMessageTap;
  final ValueChanged<ChatBubbleLongPressDetails>? onMessageLongPress;
}
