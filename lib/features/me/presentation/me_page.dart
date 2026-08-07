import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/app/theme/app_dimens.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/core/push/getui_push_service.dart';
import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:all_flutter0709/features/me/presentation/widgets/bridge_debug_panel.dart';
import 'package:all_flutter0709/features/user/presentation/helpers/user_detail_navigation.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 「我的」页；收藏 / 设置等需登录操作走 AccountGuardX。
class MePage extends ConsumerWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAccount = ref.watch(accountProvider);
    final push = ref.watch(getuiPushServiceProvider);

    return Scaffold(
      appBar: const CommonAppBar(title: '我的 Me'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          AppDimens.glassTabBarContentInset,
        ),
        children: [
          Card(
            child: ListTile(
              leading: _UserAvatar(avatar: currentAccount?.avatar),
              title: Text(
                currentAccount?.name.isNotEmpty == true
                    ? currentAccount!.name
                    : '未登录用户',
              ),
              subtitle: Text(
                currentAccount?.mobile.isNotEmpty == true
                    ? currentAccount!.mobile
                    : '请先登录以查看完整资料',
              ),
              onTap: () {
                final account = currentAccount;
                if (account == null) {
                  context.ensureLoggedIn();
                  return;
                }
                openUserDetailPage(
                  context,
                  userId: account.userId,
                  name: account.name,
                  avatar: account.avatar,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.bookmark_outline),
                  title: const Text('我的收藏'),
                  onTap: () {
                    if (!context.ensureLoggedIn()) return;
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('账号设置'),
                  onTap: () {
                    if (!context.ensureLoggedIn()) return;
                  },
                ),
                ListTile(
                  leading: Icon(
                    currentAccount == null ? Icons.login : Icons.logout,
                  ),
                  title: Text(currentAccount == null ? '去登录' : '退出登录'),
                  onTap: () async {
                    if (currentAccount == null) {
                      context.ensureLoggedIn();
                      return;
                    }

                    await ref.read(accountProvider.notifier).logout();
                    if (context.mounted) {
                      context.go(AppRoutes.login);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const BridgeDebugPanel(),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: push,
            builder: (context, _) => _GetuiDebugPanel(push: push),
          ),
        ],
      ),
    );
  }
}

class _GetuiDebugPanel extends StatelessWidget {
  const _GetuiDebugPanel({required this.push});

  final GetuiPushService push;

  @override
  Widget build(BuildContext context) {
    final clientId = push.currentClientId.trim().isEmpty
        ? '尚未获取'
        : push.currentClientId;
    final pending = push.pendingConversationId.trim().isEmpty
        ? '无'
        : push.pendingConversationId;
    final payload = push.lastBusinessPayload;
    final logs = push.eventLogs;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '个推联调',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SelectableText('ClientId: $clientId'),
            const SizedBox(height: 4),
            Text('最近事件: ${push.latestEventSummary}'),
            const SizedBox(height: 4),
            Text('待跳转会话: $pending'),
            if (payload != null) ...[
              const SizedBox(height: 4),
              SelectableText('最近 payload: $payload'),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () async {
                    await push.refreshClientIdFromSdk();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            push.currentClientId.isEmpty
                                ? 'ClientId 仍为空，请确认 SDK 已初始化'
                                : '已刷新 ClientId',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('刷新 CID'),
                ),
                FilledButton.tonal(
                  onPressed: () async {
                    await push.copyClientIdToClipboard();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ClientId 已复制')),
                      );
                    }
                  },
                  child: const Text('复制 CID'),
                ),
                FilledButton.tonal(
                  onPressed: () async {
                    await push.manualSyncMessages();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已触发 message/pull')),
                      );
                    }
                  },
                  child: const Text('手动同步'),
                ),
                FilledButton.tonal(
                  onPressed: () async {
                    await push.simulateNotificationClick();
                  },
                  child: const Text('模拟点击(无target)'),
                ),
                FilledButton.tonal(
                  onPressed: () async {
                    final target =
                        push.pendingConversationId.trim().isNotEmpty
                        ? push.pendingConversationId
                        : push.lastBusinessPayload?['targetid']?.toString();
                    await push.simulateNotificationClick(
                      targetId: target?.trim().isNotEmpty == true
                          ? target
                          : 'debug-target',
                    );
                  },
                  child: const Text('模拟点击(带target)'),
                ),
              ],
            ),
            if (logs.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                '事件日志',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 220),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    logs.join('\n'),
                    style: const TextStyle(fontSize: 12, height: 1.35),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.avatar});

  final String? avatar;

  @override
  Widget build(BuildContext context) {
    final imageUrl = ValueUtil.getQiniuUrlByFileName(avatar) ?? '';
    if (imageUrl.isEmpty) {
      return const CircleAvatar(child: Icon(Icons.person));
    }

    return CircleAvatar(backgroundImage: NetworkImage(imageUrl));
  }
}
