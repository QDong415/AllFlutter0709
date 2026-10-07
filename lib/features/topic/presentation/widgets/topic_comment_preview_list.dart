import 'dart:async';

import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_content_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 动态卡片下方的评论预览列表。
class TopicCommentPreviewList extends StatelessWidget {
  const TopicCommentPreviewList({
    super.key,
    required this.topic,
    required this.comments,
    this.onTap,
    this.onCommentUserTap,
    this.onMentionTap,
    this.onHashtagTap,
    this.onLinkTap,
  });

  final TopicModel topic;
  final List<TopicCommentModel> comments;
  final VoidCallback? onTap;
  final FutureOr<void> Function(
    TopicModel topic,
    TopicCommentModel comment,
    String userId,
    String userName,
    String? avatar,
  )?
  onCommentUserTap;
  final FutureOr<void> Function(String mention)? onMentionTap;
  final FutureOr<void> Function(String hashtag)? onHashtagTap;
  final FutureOr<void> Function(String url)? onLinkTap;

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < comments.length; i++) ...[
                  _CommentPreviewText(
                    topic: topic,
                    comment: comments[i],
                    onCommentUserTap: onCommentUserTap,
                    onMentionTap: onMentionTap,
                    onHashtagTap: onHashtagTap,
                    onLinkTap: onLinkTap,
                  ),
                  if (i != comments.length - 1) const SizedBox(height: 4),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommentPreviewText extends StatefulWidget {
  const _CommentPreviewText({
    required this.topic,
    required this.comment,
    this.onCommentUserTap,
    this.onMentionTap,
    this.onHashtagTap,
    this.onLinkTap,
  });

  final TopicModel topic;
  final TopicCommentModel comment;
  final FutureOr<void> Function(
    TopicModel topic,
    TopicCommentModel comment,
    String userId,
    String userName,
    String? avatar,
  )?
  onCommentUserTap;
  final FutureOr<void> Function(String mention)? onMentionTap;
  final FutureOr<void> Function(String hashtag)? onHashtagTap;
  final FutureOr<void> Function(String url)? onLinkTap;

  @override
  State<_CommentPreviewText> createState() => _CommentPreviewTextState();
}

class _CommentPreviewTextState extends State<_CommentPreviewText> {
  static const TextStyle _baseStyle = TextStyle(
    color: Color(0xFF333333),
    fontSize: 14,
    height: 1.45,
  );

  static const TextStyle _highlightStyle = TextStyle(
    color: Color(0xFF3399FF),
    fontWeight: FontWeight.w500,
  );

  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _CommentPreviewText oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(style: _baseStyle, children: _buildSpans()),
    );
  }

  List<InlineSpan> _buildSpans() {
    final comment = widget.comment;
    final spans = <InlineSpan>[
      _buildUserSpan(comment.userName, comment.userId, comment.avatar),
    ];

    if (comment.hasReplyTarget) {
      spans.add(const TextSpan(text: '回复'));
      spans.add(
        _buildUserSpan(comment.toUserName, comment.toUserId, comment.toAvatar),
      );
    }

    spans.add(const TextSpan(text: '：'));
    spans.addAll(_buildContentSpans(comment.previewContent));
    return spans;
  }

  TextSpan _buildUserSpan(String userName, String userId, String? avatar) {
    return TextSpan(
      text: userName,
      style: const TextStyle(
        color: Color(0xFF3399FF),
        fontWeight: FontWeight.w500,
      ),
      recognizer: _createRecognizer(() {
        final handler = widget.onCommentUserTap;
        if (handler != null) {
          return handler(
            widget.topic,
            widget.comment,
            userId,
            userName,
            avatar,
          );
        }
      }),
    );
  }

  List<InlineSpan> _buildContentSpans(String text) {
    return buildTopicContentSpans(
      text: text,
      highlightStyle: _highlightStyle,
      baseStyle: _baseStyle,
      recognizers: _recognizers,
      onMentionTap: widget.onMentionTap,
      onHashtagTap: widget.onHashtagTap,
      onLinkTap: widget.onLinkTap,
    );
  }

  TapGestureRecognizer? _createRecognizer(FutureOr<void> Function()? onTap) {
    if (onTap == null) return null;

    final recognizer = TapGestureRecognizer()
      ..onTap = () {
        final result = onTap();
        if (result is Future<void>) {
          unawaited(result);
        }
      };
    _recognizers.add(recognizer);
    return recognizer;
  }
}
