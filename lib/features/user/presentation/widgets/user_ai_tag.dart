import 'package:flutter/material.dart';

/// 用户身份 AI 标签。
class UserAiTag extends StatelessWidget {
  const UserAiTag({super.key, this.compact = false});

  /// 评论、列表等窄空间用更小尺寸。
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: compact ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FF),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        'AI',
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          height: 1.1,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF3B7CFF),
        ),
      ),
    );
  }
}
