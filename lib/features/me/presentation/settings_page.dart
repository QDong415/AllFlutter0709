import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/features/me/presentation/helpers/me_account_helper.dart';
import 'package:all_flutter0709/features/user/data/user_repository.dart';
import 'package:all_flutter0709/features/user/presentation/warning_report_page.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// 系统设置。不含夜间模式，也不含隐藏礼物 / 粉丝 / 关注。
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final UserRepository _userRepository = const UserRepository();
  bool _checking = false;

  Future<void> _setSlience(int value) async {
    final current = ref.read(accountProvider);
    if (current == null) {
      return;
    }
    try {
      final serverJson = await _userRepository.modifyProfile(<String, String>{
        'slience': '$value',
      });
      await ref
          .read(accountProvider.notifier)
          .setAccount(mergeModifiedAccount(current, serverJson));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _checkUpdate() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final info = await PackageInfo.fromPlatform();
      final latest = await _userRepository.getLastVersion();
      if (!mounted) return;
      final newer = _compareVersion(info.version, latest.name) < 0;
      if (!newer) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已是最新版本')));
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('发现新版本 ${latest.name}'),
            content: Text(
              latest.changelog.isEmpty ? '是否前往更新' : latest.changelog,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  final uri = Uri.tryParse(latest.packageUrl);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('更新'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  /// 当前版本低于服务端时返回 -1。
  int _compareVersion(String current, String latest) {
    final left = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final right = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final length = left.length > right.length ? left.length : right.length;
    for (var i = 0; i < length; i++) {
      final a = i < left.length ? left[i] : 0;
      final b = i < right.length ? right[i] : 0;
      if (a != b) return a.compareTo(b);
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountProvider);
    final slienceText = (account?.slience ?? 0) == 0 ? '响铃' : '静音';

    return Scaffold(
      backgroundColor: AppColors.bodyBackground,
      appBar: const CommonAppBar(title: '系统设置'),
      body: ListView(
        children: [
          _SettingTile(
            title: '消息提醒',
            trailing: slienceText,
            onTap: () async {
              if (!context.ensureLoggedIn()) return;
              final value = await showModalBottomSheet<int>(
                context: context,
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('响铃'),
                        onTap: () => Navigator.pop(context, 0),
                      ),
                      ListTile(
                        title: const Text('静音'),
                        onTap: () => Navigator.pop(context, 1),
                      ),
                    ],
                  ),
                ),
              );
              if (value != null) await _setSlience(value);
            },
          ),
          _SettingTile(title: '检查更新', onTap: _checkUpdate),
          _SettingTile(
            title: '黑名单',
            onTap: () {
              if (!context.ensureLoggedIn()) return;
              context.push(AppRoutes.meBlacklist);
            },
          ),
          _SettingTile(
            title: '意见反馈',
            onTap: () => openWarningReportPage(context),
          ),
          _SettingTile(
            title: '修改密码',
            onTap: () {
              if (!context.ensureLoggedIn()) return;
              context.push(AppRoutes.mePassword);
            },
          ),
          _SettingTile(
            title: '关于我们',
            onTap: () => context.push(AppRoutes.meAbout),
          ),
          if (account != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
              child: FilledButton(
                onPressed: () async {
                  await ref.read(accountProvider.notifier).logout();
                  if (context.mounted) context.go(AppRoutes.topic);
                },
                child: const Text('退出登录'),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.title, required this.onTap, this.trailing});

  final String title;
  final VoidCallback onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.divider, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 15)),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: const TextStyle(color: Color(0xFF999999)),
                ),
              const Icon(Icons.chevron_right, color: Color(0xFFC8C8C8)),
            ],
          ),
        ),
      ),
    );
  }
}
