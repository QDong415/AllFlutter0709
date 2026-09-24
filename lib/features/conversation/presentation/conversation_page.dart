import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/app/theme/app_dimens.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/features/common/widget/common_state_placeholder.dart';
import 'package:all_flutter0709/features/conversation/presentation/conversation_controller.dart';
import 'package:all_flutter0709/features/conversation/presentation/helpers/conversation_chat_args.dart';
import 'package:all_flutter0709/features/conversation/data/remind_unread_store.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/conversation_list_item.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/conversation_remind_entry.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class _RemindEntry {
  const _RemindEntry({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.kind,
    required this.location,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final RemindKind kind;
  final String location;
}

const _remindEntries = <_RemindEntry>[
  _RemindEntry(
    title: '赞',
    icon: Icons.favorite_rounded,
    iconColor: Color(0xFFFF6B6B),
    kind: RemindKind.praise,
    location: '${AppRoutes.conversation}/remind/2',
  ),
  _RemindEntry(
    title: '评论',
    icon: Icons.chat_bubble_rounded,
    iconColor: Color(0xFF4C9AFF),
    kind: RemindKind.comment,
    location: '${AppRoutes.conversation}/remind/1',
  ),
  _RemindEntry(
    title: '新粉丝',
    icon: Icons.person_add_alt_1_rounded,
    iconColor: Color(0xFFFFB020),
    kind: RemindKind.fans,
    location: '${AppRoutes.conversation}/fans',
  ),
  _RemindEntry(
    title: '@我',
    icon: Icons.alternate_email_rounded,
    iconColor: Color(0xFF7B61FF),
    kind: RemindKind.at,
    location: '${AppRoutes.conversation}/remind/3',
  ),
];

/// 会话列表页。
class ConversationPage extends ConsumerWidget {
  const ConversationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAccount = ref.watch(accountProvider);
    final controller = ref.read(conversationControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.bodyBackground,
      appBar: const CommonAppBar(title: '聊天'),
      body: currentAccount == null
          ? CommonStatePlaceholder(
              imageAsset: 'assets/icons/tips_empty_ban.png',
              text: '需要登录后才能查看',
              actionText: '去登录',
              onTap: () => context.ensureLoggedIn(),
            )
          : ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final state = controller.conversationsState;
                return state.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => _ConversationErrorView(
                    message: error.toString(),
                    onRetry: controller.syncMessagesFromServer,
                  ),
                  data: (conversations) {
                    return RefreshIndicator(
                      onRefresh: controller.syncMessagesFromServer,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollStartNotification &&
                              notification.dragDetails != null) {
                            ConversationListItem.closeOpenSwipe();
                          }
                          return false;
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.only(
                            bottom: AppDimens.glassTabBarContentInset,
                          ),
                          itemBuilder: (context, index) {
                            if (index < _remindEntries.length) {
                              final entry = _remindEntries[index];
                              return ConversationRemindEntry(
                                title: entry.title,
                                icon: entry.icon,
                                iconColor: entry.iconColor,
                                unreadCount: controller.remindUnreadCount(
                                  entry.kind,
                                ),
                                onTap: () {
                                  if (!context.ensureLoggedIn()) return;
                                  context.push(entry.location);
                                },
                              );
                            }
                            final item =
                                conversations[index - _remindEntries.length];
                            return ConversationListItem(
                              key: ValueKey(item.conversationId),
                              summaryModel: item,
                              onTap: () {
                                if (!context.ensureLoggedIn()) return;
                                context.push(
                                  '${AppRoutes.conversation}/chat/${item.conversationId}',
                                  extra: ConversationChatArgs(
                                    peerName: item.name,
                                    peerAvatar: item.avatar,
                                    peerUserType: item.userType,
                                  ),
                                );
                              },
                              onDelete: () {
                                controller.deleteConversation(
                                  item.conversationId,
                                );
                              },
                            );
                          },
                          separatorBuilder: (_, _) => const Divider(
                            height: AppDimens.dividerThickness,
                            thickness: AppDimens.dividerThickness,
                            color: AppColors.divider,
                          ),
                          itemCount:
                              _remindEntries.length + conversations.length,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
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
