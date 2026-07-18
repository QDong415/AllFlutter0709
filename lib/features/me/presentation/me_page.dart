import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MePage extends ConsumerWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAccount = ref.watch(accountProvider);

    return Scaffold(
      appBar: const CommonAppBar(title: '我的 Me'),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.bookmark_outline),
                  title: const Text('我的收藏'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('账号设置'),
                  onTap: () {},
                ),
                ListTile(
                  leading: Icon(
                    currentAccount == null ? Icons.login : Icons.logout,
                  ),
                  title: Text(currentAccount == null ? '去登录' : '退出登录'),
                  onTap: () async {
                    if (currentAccount == null) {
                      context.go(AppRoutes.login);
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
        ],
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
