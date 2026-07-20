import 'dart:async';

import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

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

    return Material(
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
  static final RegExp _tokenPattern = RegExp(
    r'(https?:\/\/[^\s]+)|(@[A-Za-z0-9_\-\u4e00-\u9fa5]+)|(#[^#\s]+#?)',
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
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Color(0xFF333333),
          fontSize: 14,
          height: 1.45,
        ),
        children: _buildSpans(),
      ),
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
    final spans = <InlineSpan>[];
    var start = 0;

    for (final match in _tokenPattern.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }

      final token = match.group(0)!;
      spans.add(
        TextSpan(
          text: token,
          style: const TextStyle(
            color: Color(0xFF3399FF),
            fontWeight: FontWeight.w500,
          ),
          recognizer: _createTokenRecognizer(token),
        ),
      );
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return spans;
  }

  TapGestureRecognizer? _createTokenRecognizer(String token) {
    FutureOr<void> Function()? onTap;
    if (token.startsWith('http://') || token.startsWith('https://')) {
      final handler = widget.onLinkTap;
      if (handler != null) {
        onTap = () => handler(token);
      }
    } else if (token.startsWith('@')) {
      final handler = widget.onMentionTap;
      if (handler != null) {
        onTap = () => handler(token.substring(1));
      }
    } else if (token.startsWith('#')) {
      final handler = widget.onHashtagTap;
      if (handler != null) {
        onTap = () => handler(token);
      }
    }

    return _createRecognizer(onTap);
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
