import 'package:all_flutter0709/features/comment/data/models/comment_display_model.dart';
import 'package:flutter/material.dart';

class CommentItemSingleTips extends StatelessWidget {
  const CommentItemSingleTips({
    required this.item,
    required this.onTap,
    super.key,
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

    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 20,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 0.6,
                          height: 23,
                          color: const Color(0xFFDCDCDC),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 23),
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
          if (showCommentSeparator(displayType))
            const Padding(
              padding: EdgeInsets.only(left: 61, top: 10),
              child: Divider(height: 0.6, thickness: 0.6),
            ),
        ],
      ),
    );
  }
}
