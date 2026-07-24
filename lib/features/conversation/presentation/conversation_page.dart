import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/app/theme/app_dimens.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/features/common/widget/common_state_placeholder.dart';
import 'package:all_flutter0709/features/conversation/presentation/conversation_controller.dart';
import 'package:all_flutter0709/features/conversation/presentation/helpers/conversation_chat_args.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/conversation_list_item.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 会话列表页；UI 对齐 iTopicX `ConversationFragment`。
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
                    if (conversations.isEmpty) {
                      return _ConversationEmptyView(
                        onRefresh: controller.syncMessagesFromServer,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: controller.syncMessagesFromServer,
                      child: ListView.separated(
                        itemBuilder: (context, index) {
                          final item = conversations[index];
                          return ConversationListItem(
                            summaryModel: item,
                            onTap: () {
                              if (!context.ensureLoggedIn()) return;
                              context.push(
                                '${AppRoutes.conversation}/chat/${item.conversationId}',
                                extra: ConversationChatArgs(
                                  peerName: item.name,
                                  peerAvatar: item.avatar,
                                ),
                              );
                            },
                          );
                        },
                        separatorBuilder: (_, _) => const Divider(
                          height: AppDimens.dividerThickness,
                          thickness: AppDimens.dividerThickness,
                          color: AppColors.divider,
                        ),
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
