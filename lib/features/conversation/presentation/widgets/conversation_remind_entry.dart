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
              SizedBox(
                width: 60,
                height: 72,
                child: Stack(
                  children: [
                    Positioned(
                      left: 10,
                      top: 12,
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: iconColor,
                        child: Icon(icon, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 7, right: 7),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.titleText,
                    ),
                  ),
                ),
              ),
              if (unreadCount > 0) ...[
                _UnreadBadge(text: badgeText),
                const SizedBox(width: 4),
              ],
              const Icon(Icons.chevron_right, color: Color(0xFFC8C8C8)),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// 与会话列表未读数同一套小圆点，不拉伸行高。
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFE64C64),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          height: 1.2,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
