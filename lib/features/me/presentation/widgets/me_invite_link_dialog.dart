import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/config/app_config.dart';
import 'package:all_flutter0709/features/me/presentation/helpers/invite_system_share_helper.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 邀请链接弹框：奖励说明、下载地址，点链接复制，点分享调系统面板。
class MeInviteLinkDialog extends StatelessWidget {
  const MeInviteLinkDialog({
    super.key,
    required this.link,
    required this.rewardHint,
    required this.shareText,
    required this.onCopyLink,
    required this.onShare,
  });

  final String link;
  final String rewardHint;
  final String shareText;
  final Future<void> Function() onCopyLink;
  final Future<void> Function() onShare;

  /// 弹出邀请链接。
  static Future<void> show(
    BuildContext context, {
    required String inviteCode,
    required String inviterName,
  }) {
    final config = AppConfig.instance;
    final link = config.buildInviteLink(inviteCode);
    final rewardHint =
        '被邀请新用户获得 ${config.inviteInviteeCoin} 金币，你获得 ${config.inviteRewardCoin} 金币';
    final name = inviterName.trim().isEmpty ? '我' : inviterName.trim();
    final shareText = '$name邀请你注册梦缘App，安装链接：$link';
    final inviteTitle = '$name邀请你注册梦缘App';
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return MeInviteLinkDialog(
          link: link,
          rewardHint: rewardHint,
          shareText: shareText,
          onCopyLink: () async {
            await Clipboard.setData(ClipboardData(text: link));
            if (context.mounted) {
              AppToast.show(context, '已复制');
            }
          },
          onShare: () async {
            await shareInviteToSystem(
              link: link,
              shareText: shareText,
              inviteTitle: inviteTitle,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: const Color(0x33000000),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(22, 22, 22, 10),
                child: Text(
                  '邀请新用户',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.titleText,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                child: Text(
                  rewardHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Color(0xFF5B5B5B),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                child: GestureDetector(
                  onTap: () {
                    onCopyLink();
                  },
                  child: Text(
                    link,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: AppColors.link,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.link,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 0.6, color: AppColors.divider),
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    Expanded(
                      child: _DialogAction(
                        label: '关闭',
                        color: const Color(0xFF5B5B5B),
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(
                      width: 0.6,
                      height: 48,
                      child: ColoredBox(color: AppColors.divider),
                    ),
                    Expanded(
                      child: _DialogAction(
                        label: '分享',
                        color: AppColors.link,
                        onTap: () {
                          onShare();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogAction extends StatelessWidget {
  const _DialogAction({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Center(
        child: Text(
          label,
          style: TextStyle(fontSize: 16, color: color),
        ),
      ),
    );
  }
}