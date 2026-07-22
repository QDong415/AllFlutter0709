import 'package:all_flutter0709/features/comment/data/models/comment_display_model.dart';
import 'package:all_flutter0709/features/comment/data/models/comment_model.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_like_button.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_picture_grid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CommentItem extends StatelessWidget {
  const CommentItem({
    required this.comment,
    required this.isChild,
    required this.authorUserId,
    required this.displayType,
    required this.onTap,
    required this.onLikeTap,
    super.key,
  });

  final CommentModel comment;
  final bool isChild;
  final String authorUserId;
  final CommentDisplayType displayType;
  final VoidCallback onTap;
  final VoidCallback onLikeTap;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = comment.avatar ?? '';
    final isAuthor = authorUserId.isNotEmpty && authorUserId == comment.userId;

    return Padding(
      padding: EdgeInsets.only(top: isChild ? 0 : 8),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CommentTree(
                    isChild: isChild,
                    displayType: displayType,
                    avatarUrl: avatarUrl,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: isChild ? 12 : 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  comment.userName.isEmpty
                                      ? '匿名用户'
                                      : comment.userName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF133465),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isAuthor) ...[
                                const SizedBox(width: 6),
                                const _AuthorBadge(),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          _CommentRichText(comment: comment),
                          if (comment.pictures.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            TopicPictureGrid(pictures: comment.pictures),
                          ],
                          if (comment.isPending) ...[
                            const SizedBox(height: 4),
                            const Row(
                              children: [
                                Text(
                                  '发送中...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: isChild ? 12 : 10),
                    child: _CommentLikeColumn(
                      comment: comment,
                      onTap: onLikeTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showCommentSeparator(displayType))
            Padding(
              padding: EdgeInsets.only(left: isChild ? 85 : 61, top: 8),
              child: const Divider(height: 0.6, thickness: 0.6),
            ),
        ],
      ),
    );
  }
}

class _CommentTree extends StatelessWidget {
  const _CommentTree({
    required this.isChild,
    required this.displayType,
    required this.avatarUrl,
  });

  final bool isChild;
  final CommentDisplayType displayType;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    if (!isChild) {
      return Padding(
        padding: const EdgeInsets.only(left: 12, top: 10),
        child: SizedBox(
          width: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CommentAvatar(size: 36, avatarUrl: avatarUrl),
              if (displayType == CommentDisplayType.fatherCommentContainsChild)
                Expanded(
                  child: Center(
                    child: Container(
                      width: 0.6,
                      color: const Color(0xFFDCDCDC),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: SizedBox(
        width: 64,
        child: Stack(
          children: [
            Positioned(
              left: 19.7,
              top: 0,
              bottom: displayType == CommentDisplayType.childCommentMiddle
                  ? 0
                  : null,
              child: Container(
                width: 0.6,
                height: displayType == CommentDisplayType.childCommentMiddle
                    ? null
                    : 24,
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
            Positioned(
              left: 40,
              top: 10,
              child: _CommentAvatar(size: 24, avatarUrl: avatarUrl),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentAvatar extends StatelessWidget {
  const _CommentAvatar({
    required this.size,
    required this.avatarUrl,
  });

  final double size;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE8E8E8),
        border: Border.all(color: const Color(0xFFDCDCDC), width: 0.6),
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl.isEmpty
          ? const Icon(Icons.person, size: 14, color: Color(0xFFB7B7B7))
          : CachedNetworkImage(
              imageUrl: avatarUrl,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) =>
                  const Icon(Icons.person, size: 14, color: Color(0xFFB7B7B7)),
            ),
    );
  }
}

class _CommentRichText extends StatelessWidget {
  const _CommentRichText({required this.comment});

  final CommentModel comment;

  @override
  Widget build(BuildContext context) {
    final baseStyle = const TextStyle(
      fontSize: 15,
      height: 1.45,
      color: Color(0xFF333333),
    );
    final activeStyle = baseStyle.copyWith(
      color: const Color(0xFF133465),
    );
    final timeStyle = const TextStyle(
      fontSize: 12,
      height: 1.45,
      color: Color(0xFF919191),
    );
    final content = comment.displayContent;
    final timeText = _formatCommentTimeText(comment.createTime);

    if (!comment.hasReplyTarget) {
      return RichText(
        text: TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: content),
            if (timeText.isNotEmpty) ...[
              const TextSpan(text: ' '),
              TextSpan(text: timeText, style: timeStyle),
            ],
          ],
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          const TextSpan(text: '回复 '),
          TextSpan(text: comment.toUserName, style: activeStyle),
          const TextSpan(text: '：'),
          TextSpan(text: content),
          if (timeText.isNotEmpty) ...[
            const TextSpan(text: ' '),
            TextSpan(text: timeText, style: timeStyle),
          ],
        ],
      ),
    );
  }
}

class _AuthorBadge extends StatelessWidget {
  const _AuthorBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEAA55E), width: 0.6),
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Text(
        '作者',
        style: TextStyle(
          fontSize: 10,
          color: Color(0xFFEAA55E),
          height: 1.1,
        ),
      ),
    );
  }
}

class _CommentLikeColumn extends StatelessWidget {
  const _CommentLikeColumn({
    required this.comment,
    required this.onTap,
  });

  final CommentModel comment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final asset = comment.isLiked
        ? TopicLikeButton.likeIconOnAsset
        : TopicLikeButton.likeIconOffAsset;
    final textColor = comment.isLiked
        ? TopicLikeButton.likedColor
        : const Color(0xFF999999);
    final countText = comment.likeCount > 0 ? '${comment.likeCount}' : '';

    return SizedBox(
      width: 36,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.only(top: 2, right: 2),
          child: Column(
            children: [
              Image.asset(
                asset,
                width: 18,
                height: 18,
                color: comment.isLiked ? null : const Color(0xFFB0B0B0),
              ),
              if (countText.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  countText,
                  style: TextStyle(fontSize: 14, color: textColor, height: 1),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _formatCommentTimeText(int timestamp) {
  if (timestamp <= 0) return '--';
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
