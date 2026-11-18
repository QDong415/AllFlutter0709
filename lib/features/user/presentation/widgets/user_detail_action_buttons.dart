import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/app/theme/app_palette.dart';
import 'package:all_flutter0709/features/user/presentation/helpers/user_follow_helper.dart';
import 'package:flutter/material.dart';

/// 个人主页操作按钮区：看自己显示「编辑资料」，看他人显示「私信 + 关注」。
class UserDetailActionButtons extends StatelessWidget {
  const UserDetailActionButtons({
    super.key,
    required this.isSelf,
    required this.followStatus,
    required this.isFollowLoading,
    required this.onChatTap,
    required this.onFollowTap,
    required this.onEditTap,
  });

  final bool isSelf;
  final int followStatus;
  final bool isFollowLoading;
  final VoidCallback onChatTap;
  final VoidCallback onFollowTap;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final dark = context.palette.brightness == Brightness.dark;
    if (isSelf) {
      return _OutlineActionButton(
        label: '编辑资料',
        iconAsset: context.themedAsset(
          'assets/icons/user/profile_icon_edit_normal.png',
          'assets/icons/user/profile_icon_edit_dark.png',
        ),
        onTap: onEditTap,
      );
    }

    final isFollowAction = UserFollowHelper.isFollowAction(followStatus);

    return Row(
      children: [
        Expanded(
          child: _OutlineActionButton(
            label: '私信',
            iconAsset: context.themedAsset(
              'assets/icons/user/profile_icon_chat_normal.png',
              'assets/icons/user/profile_icon_chat_dark.png',
            ),
            onTap: onChatTap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FollowActionButton(
            followStatus: followStatus,
            isLoading: isFollowLoading,
            isFollowAction: isFollowAction,
            isDark: dark,
            onTap: onFollowTap,
          ),
        ),
      ],
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({
    required this.label,
    required this.iconAsset,
    required this.onTap,
  });

  final String label;
  final String iconAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: palette.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(iconAsset, width: 16, height: 16),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(fontSize: 14, color: palette.titleText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FollowActionButton extends StatelessWidget {
  const _FollowActionButton({
    required this.followStatus,
    required this.isLoading,
    required this.isFollowAction,
    required this.isDark,
    required this.onTap,
  });

  final int followStatus;
  final bool isLoading;
  final bool isFollowAction;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final background = isFollowAction ? AppColors.accent : palette.card;
    final textColor = isFollowAction ? Colors.white : palette.titleText;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: isFollowAction ? null : Border.all(color: palette.divider),
          ),
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: textColor,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      UserFollowHelper.iconAssetOf(followStatus, dark: isDark),
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      UserFollowHelper.labelOf(followStatus),
                      style: TextStyle(fontSize: 14, color: textColor),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
