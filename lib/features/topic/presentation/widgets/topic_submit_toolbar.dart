import 'package:flutter/material.dart';

/// 发布页 @、表情图标，来自 Android `submit_at_normal` / `comment_emoji_black_normal`。
abstract final class TopicSubmitAssets {
  static const at = 'assets/icons/topic/submit_at_normal.png';
  static const emoji = 'assets/icons/topic/comment_emoji_black_normal.png';
}

/// 发布页输入框下方：@ 与表情按钮。
class TopicSubmitToolbar extends StatelessWidget {
  const TopicSubmitToolbar({
    super.key,
    required this.onAtTap,
    required this.onEmojiTap,
  });

  final VoidCallback onAtTap;
  final VoidCallback onEmojiTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: onAtTap,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            icon: Image.asset(TopicSubmitAssets.at, width: 30, height: 30),
          ),
          IconButton(
            onPressed: onEmojiTap,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            icon: Image.asset(
              TopicSubmitAssets.emoji,
              width: 35,
              height: 35,
            ),
          ),
        ],
      ),
    );
  }
}
