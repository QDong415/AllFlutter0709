import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

final RegExp topicContentTokenPattern = RegExp(
  r'(https?:\/\/[^\s]+)|(@[A-Za-z0-9_\-\u4e00-\u9fa5]+)|(#[^#\s]+#?)',
);

/// 把正文拆成普通字和可点击的 @ / # / 链接。
List<InlineSpan> buildTopicContentSpans({
  required String text,
  required TextStyle highlightStyle,
  required List<TapGestureRecognizer> recognizers,
  FutureOr<void> Function(String mention)? onMentionTap,
  FutureOr<void> Function(String hashtag)? onHashtagTap,
  FutureOr<void> Function(String url)? onLinkTap,
}) {
  final spans = <InlineSpan>[];
  var start = 0;
  for (final match in topicContentTokenPattern.allMatches(text)) {
    if (match.start > start) {
      spans.add(TextSpan(text: text.substring(start, match.start)));
    }
    final token = match.group(0)!;
    spans.add(
      TextSpan(
        text: token,
        style: highlightStyle,
        recognizer: _contentRecognizer(
          token: token,
          recognizers: recognizers,
          onMentionTap: onMentionTap,
          onHashtagTap: onHashtagTap,
          onLinkTap: onLinkTap,
        ),
      ),
    );
    start = match.end;
  }
  if (start < text.length) {
    spans.add(TextSpan(text: text.substring(start)));
  }
  return spans;
}

TapGestureRecognizer? _contentRecognizer({
  required String token,
  required List<TapGestureRecognizer> recognizers,
  FutureOr<void> Function(String mention)? onMentionTap,
  FutureOr<void> Function(String hashtag)? onHashtagTap,
  FutureOr<void> Function(String url)? onLinkTap,
}) {
  FutureOr<void> Function()? onTap;
  if (token.startsWith('http://') || token.startsWith('https://')) {
    if (onLinkTap != null) {
      onTap = () => onLinkTap(token);
    }
  } else if (token.startsWith('@')) {
    if (onMentionTap != null) {
      onTap = () => onMentionTap(token.substring(1));
    }
  } else if (token.startsWith('#')) {
    if (onHashtagTap != null) {
      onTap = () => onHashtagTap(token);
    }
  }
  if (onTap == null) {
    return null;
  }
  final recognizer = TapGestureRecognizer()
    ..onTap = () {
      final result = onTap?.call();
      if (result is Future<void>) {
        unawaited(result);
      }
    };
  recognizers.add(recognizer);
  return recognizer;
}

/// 动态正文：普通文字 + @ / # / 链接高亮。
class TopicContentText extends StatefulWidget {
  const TopicContentText({
    super.key,
    required this.text,
    this.style,
    this.highlightStyle,
    this.onMentionTap,
    this.onHashtagTap,
    this.onLinkTap,
    this.maxLines,
  });

  final String text;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final FutureOr<void> Function(String mention)? onMentionTap;
  final FutureOr<void> Function(String hashtag)? onHashtagTap;
  final FutureOr<void> Function(String url)? onLinkTap;
  final int? maxLines;

  @override
  State<TopicContentText> createState() => _TopicContentTextState();
}

class _TopicContentTextState extends State<TopicContentText> {
  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TopicContentText oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style ?? const TextStyle(fontSize: 18);
    final activeStyle =
        widget.highlightStyle ??
        baseStyle.copyWith(
          color: const Color(0xFF2F7CF6),
          fontWeight: FontWeight.w500,
        );

    return Text.rich(
      TextSpan(
        style: baseStyle.copyWith(color: baseStyle.color ?? Colors.black87),
        children: _buildSpans(activeStyle),
      ),
      maxLines: widget.maxLines,
      overflow: widget.maxLines == null
          ? TextOverflow.clip
          : TextOverflow.ellipsis,
    );
  }

  List<InlineSpan> _buildSpans(TextStyle activeStyle) {
    return buildTopicContentSpans(
      text: widget.text,
      highlightStyle: activeStyle,
      recognizers: _recognizers,
      onMentionTap: widget.onMentionTap,
      onHashtagTap: widget.onHashtagTap,
      onLinkTap: widget.onLinkTap,
    );
  }
}
