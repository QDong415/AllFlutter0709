import 'package:all_flutter0709/features/conversation/presentation/models/chat_item.dart';
import 'package:all_flutter0709/features/conversation/presentation/models/chat_message_interaction.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_image_bubble.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_message_row.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_text_bubble.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_voice_bubble.dart';
import 'package:flutter/material.dart';

/// 聊天气泡列表单项：时间 tips 或一条消息行。
class ChatListItemWidget extends StatelessWidget {
  const ChatListItemWidget({
    super.key,
    required this.item,
    this.actions = ChatMessageActions.empty,
    this.playingMessageId,
    this.selectedMessageId,
  });

  final ChatItem item;
  final ChatMessageActions actions;
  final String? playingMessageId;
  final String? selectedMessageId;

  @override
  Widget build(BuildContext context) {
    return switch (item) {
      final TimeItem timeItem => _TimeItemWidget(item: timeItem),
      final TextMessage textItem => ChatMessageRow(
        item: textItem,
        actions: actions,
        bubble: ChatTextBubble(
          item: textItem,
          isSelected: selectedMessageId == textItem.id,
        ),
      ),
      final VoiceMessage voiceItem => ChatMessageRow(
        item: voiceItem,
        actions: actions,
        bubble: ChatVoiceBubble(
          item: voiceItem,
          isPlaying: playingMessageId == voiceItem.id,
          isSelected: selectedMessageId == voiceItem.id,
        ),
      ),
      final ImageMessage imageItem => ChatMessageRow(
        item: imageItem,
        actions: actions,
        bubble: ChatImageBubble(
          item: imageItem,
          isSelected: selectedMessageId == imageItem.id,
        ),
      ),
    };
  }
}

class _TimeItemWidget extends StatelessWidget {
  const _TimeItemWidget({required this.item});

  final TimeItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          item.label,
          style: const TextStyle(
            color: Color(0xFFB2B2B2),
            fontSize: 12,
            height: 1,
          ),
        ),
      ),
    );
  }
}
