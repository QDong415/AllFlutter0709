import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';
import 'package:all_flutter0709/features/conversation/presentation/mappers/chat_item_mapper.dart';
import 'package:all_flutter0709/features/conversation/presentation/models/chat_item.dart';
import 'package:all_flutter0709/features/conversation/presentation/models/chat_message_interaction.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_message_list_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 聊天消息区域：监听当前会话、映射展示项并统一分发气泡交互。
class ChatMessageArea extends StatelessWidget {
  const ChatMessageArea({
    super.key,
    required this.messagesListenable,
    required this.myAvatar,
    required this.peerAvatar,
    required this.scrollController,
    required this.onRefresh,
    required this.onRetry,
    required this.onPointerDown,
    required this.onItemsChanged,
    required this.onMessageTap,
    required this.onMessageLongPress,
    required this.onAvatarTap,
    this.playingMessageId,
    this.selectedMessageId,
  });

  final ValueListenable<AsyncValue<List<ConversationMessage>>>
  messagesListenable;
  final String myAvatar;
  final String peerAvatar;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final VoidCallback onPointerDown;
  final ValueChanged<int> onItemsChanged;
  final void Function(MessageItem message, List<ChatItem> itemList)
  onMessageTap;
  final ValueChanged<ChatBubbleLongPressDetails> onMessageLongPress;
  final ValueChanged<MessageItem> onAvatarTap;
  final String? playingMessageId;
  final String? selectedMessageId;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AsyncValue<List<ConversationMessage>>>(
      valueListenable: messagesListenable,
      builder: (context, state, _) {
        final messageList = state is AsyncData<List<ConversationMessage>>
            ? state.value
            : const <ConversationMessage>[];
        final itemList = buildChatItems(
          messageList,
          myAvatar: myAvatar,
          peerAvatar: peerAvatar,
        );
        if (state.hasValue && itemList.isNotEmpty) {
          onItemsChanged(itemList.length);
        }
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => onPointerDown(),
          child: ChatMessageListView(
            state: state,
            items: itemList,
            scrollController: scrollController,
            playingMessageId: playingMessageId,
            selectedMessageId: selectedMessageId,
            onRefresh: onRefresh,
            onRetry: onRetry,
            actions: ChatMessageActions(
              onMessageTap: (message) => onMessageTap(message, itemList),
              onMessageLongPress: onMessageLongPress,
              onAvatarTap: onAvatarTap,
            ),
          ),
        );
      },
    );
  }
}
