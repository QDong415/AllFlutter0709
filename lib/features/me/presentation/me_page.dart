import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/core/account/account.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    final account = Account.instance;
    final user = account.currentUser;

    return Scaffold(
      appBar: const CommonAppBar(title: '我的 Me'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(user?.name ?? '未登录用户'),
              subtitle: Text(user?.email ?? '请先登录以查看完整资料'),
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
                    user == null ? Icons.login : Icons.logout,
                  ),
                  title: Text(user == null ? '去登录' : '退出登录'),
                  onTap: () {
                    if (user == null) {
                      context.go(AppRoutes.login);
                      return;
                    }
                    account.logout();
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
