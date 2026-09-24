import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// 会话列表顶部的固定提醒入口（赞 / 评论 / 新粉丝 / @我）。
class ConversationRemindEntry extends StatelessWidget {
  const ConversationRemindEntry({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.unreadCount,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badgeText = unreadCount > 99 ? '99+' : '$unreadCount';
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              const SizedBox(width: 16),
              CircleAvatar(
                radius: 24,
                backgroundColor: iconColor,
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.titleText,
                  ),
                ),
              ),
              if (unreadCount > 0)
                Container(
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE54545),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      height: 1.1,
                    ),
                  ),
                ),
              const Icon(Icons.chevron_right, color: Color(0xFFC8C8C8)),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
