import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';
import 'package:all_flutter0709/features/conversation/presentation/models/chat_item.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 聊天气泡消息列表：加载 / 错误 / 空态 / 消息列表。
///
/// 使用 `reverse: true`，新消息自然出现在底部，避免先错位再滚底的抖动。
class ChatMessageListView extends StatelessWidget {
  const ChatMessageListView({
    super.key,
    required this.state,
    required this.items,
    required this.scrollController,
    required this.onRefresh,
    required this.onRetry,
    required this.onImageTap,
    this.onAvatarTap,
    this.onUserDragScroll,
  });

  final AsyncValue<List<ConversationMessage>> state;
  final List<ChatItem> items;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final ValueChanged<ImageMessage> onImageTap;
  final ValueChanged<MessageItem>? onAvatarTap;

  /// 用户手指拖动列表时回调（用于收起键盘 / 面板）。
  final VoidCallback? onUserDragScroll;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded),
              const SizedBox(height: 12),
              Text(error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.tonal(onPressed: onRetry, child: const Text('重试')),
            ],
          ),
        ),
      ),
      data: (messages) {
        if (messages.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              controller: scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(5, 0, 5, 8),
              children: const [SizedBox(height: 160)],
            ),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification &&
                notification.dragDetails != null) {
              onUserDragScroll?.call();
            }
            return false;
          },
          child: ListView.builder(
            controller: scrollController,
            reverse: true,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(5, 8, 5, 0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              // reverse 下列表 index 0 在底部，对应时间正序的最后一条。
              final item = items[items.length - 1 - index];
              return ChatListItemWidget(
                item: item,
                onImageTap: onImageTap,
                onAvatarTap: onAvatarTap,
              );
            },
          ),
        );
      },
    );
  }
}
