import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';
import 'package:all_flutter0709/features/conversation/presentation/models/chat_item.dart';
import 'package:all_flutter0709/features/conversation/presentation/models/chat_message_interaction.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 聊天气泡消息列表：加载 / 错误 / 空态 / 消息列表。
///
/// 使用 `reverse: true` 保持新消息贴底滚动体验；
/// 内容较少时通过 [Align] + [shrinkWrap] 顶到视觉上方，避免整页沉底。
class ChatMessageListView extends StatelessWidget {
  const ChatMessageListView({
    super.key,
    required this.state,
    required this.items,
    required this.scrollController,
    required this.onRefresh,
    required this.onRetry,
    this.actions = ChatMessageActions.empty,
    this.playingMessageId,
    this.selectedMessageId,
  });

  final AsyncValue<List<ConversationMessage>> state;
  final List<ChatItem> items;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final ChatMessageActions actions;
  final String? playingMessageId;
  final String? selectedMessageId;

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
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
              children: const [SizedBox(height: 160)],
            ),
          );
        }

        // reverse 列表在 shrinkWrap=false 时会占满视口，短列表因此沉在底部，
        // 键盘/面板出现时还会跟随底边整体上移；短列表必须 shrinkWrap 后再
        // Align.top，才能固定在顶部。长列表继续 shrinkWrap 虽然显示正确，
        // 但滚动时需要反复计算内容尺寸，因此超过一屏后切回普通懒加载列表。
        // 20 个展示项通常已超过手机一屏，也把 shrinkWrap 的最坏开销限制住。
        final shouldShrinkWrap = items.length <= 20;
        final messageList = ListView.builder(
          controller: scrollController,
          reverse: true,
          shrinkWrap: shouldShrinkWrap,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            // reverse 下列表 index 0 在底部，对应时间正序的最后一条。
            final item = items[items.length - 1 - index];
            return ChatListItemWidget(
              key: switch (item) {
                TimeItem() => ValueKey('time_$index'),
                RecallItem(:final id) => ValueKey('recall_$id'),
                MessageItem(:final id) => ValueKey('msg_$id'),
              },
              item: item,
              actions: actions,
              playingMessageId: playingMessageId,
              selectedMessageId: selectedMessageId,
            );
          },
        );

        if (!shouldShrinkWrap) {
          return messageList;
        }
        return Align(alignment: Alignment.topCenter, child: messageList);
      },
    );
  }
}
