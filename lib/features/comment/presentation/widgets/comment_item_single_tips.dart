import 'package:all_flutter0709/features/comment/data/models/comment_display_model.dart';
import 'package:flutter/material.dart';

/// 评论区「加载全部回复 / 收起 / loading」提示行
class CommentItemSingleTips extends StatelessWidget {
  const CommentItemSingleTips({
    super.key,
    required this.item,
    required this.onTap,
  });

  final CommentDisplayModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayType = item.displayType!;
    final label = switch (displayType) {
      CommentDisplayType.loadingMoreComment => '',
      CommentDisplayType.packUpComment => '已经是全部回复了',
      CommentDisplayType.showMoreComment => '加载全部${item.totalChildCount}条回复',
      _ => '',
    };

    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 64,
                    child: Stack(
                      children: [
                        // 与子评论树竖线对齐：left 12 + 19.7
                        Positioned(
                          left: 19.7,
                          top: 0,
                          child: Container(
                            width: 0.6,
                            height: 24,
                            color: const Color(0xFFDCDCDC),
                          ),
                        ),
                        Positioned(
                          left: 20,
                          top: 24,
                          child: Container(
                            width: 20,
                            height: 0.6,
                            color: const Color(0xFFDCDCDC),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 2),
                      child: displayType == CommentDisplayType.loadingMoreComment
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : GestureDetector(
                              onTap: onTap,
                              child: Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF133465),
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            if (showCommentSeparator(displayType))
              const Padding(
                padding: EdgeInsets.only(left: 61, top: 10),
                child: Divider(height: 0.6, thickness: 0.6),
              ),
          ],
        ),
      ),
    );
  }
}
