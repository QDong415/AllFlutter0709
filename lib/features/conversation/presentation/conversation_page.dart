import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:all_flutter0709/features/conversation/presentation/conversation_controller.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ConversationPage extends ConsumerWidget {
  const ConversationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(conversationControllerProvider);

    return Scaffold(
      appBar: const CommonAppBar(title: '对话 Conversation'),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final state = controller.conversationsState;
          return state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => _ConversationErrorView(
              message: error.toString(),
              onRetry: controller.syncMessagesFromServer,
            ),
            data: (conversations) {
              if (conversations.isEmpty) {
                return _ConversationEmptyView(
                  onRefresh: controller.syncMessagesFromServer,
                );
              }

              return RefreshIndicator(
                onRefresh: controller.syncMessagesFromServer,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final item = conversations[index];
                    final avatarUrl = ValueUtil.getQiniuUrlByFileName(
                      item.avatar,
                      keepOriginal: true,
                    );
                    return ListTile(
                      onTap: () {
                        context.push(
                          '${AppRoutes.conversation}/chat/${item.conversationId}',
                        );
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundImage: avatarUrl == null
                            ? null
                            : NetworkImage(avatarUrl),
                        child: avatarUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(
                        item.name.isEmpty
                            ? '用户${item.conversationId}'
                            : item.name,
                      ),
                      subtitle: Text(
                        item.latestMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatConversationTime(item.latestTime),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          if (item.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE53935),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(99),
                                ),
                              ),
                              child: Text(
                                item.unreadCount > 99
                                    ? '99+'
                                    : '${item.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemCount: conversations.length,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ConversationEmptyView extends StatelessWidget {
  const _ConversationEmptyView({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.55,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.forum_outlined,
                  size: 52,
                  color: Color(0xFF9E9E9E),
                ),
                const SizedBox(height: 12),
                const Text('还没有会话'),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: onRefresh,
                  child: const Text('重新同步'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ConversationErrorView extends StatelessWidget {
  const _ConversationErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFD93025),
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}

String _formatConversationTime(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final difference = today.difference(day).inDays;

  if (difference <= 0) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  if (difference == 1) {
    return '昨天';
  }

  return '${dateTime.month}/${dateTime.day}';
}
