import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class TopicContentText extends StatefulWidget {
  const TopicContentText({
    super.key,
    required this.text,
    this.style,
    this.highlightStyle,
    this.onMentionTap,
    this.onHashtagTap,
    this.onLinkTap,
  });

  final String text;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final FutureOr<void> Function(String mention)? onMentionTap;
  final FutureOr<void> Function(String hashtag)? onHashtagTap;
  final FutureOr<void> Function(String url)? onLinkTap;

  @override
  State<TopicContentText> createState() => _TopicContentTextState();
}

class _TopicContentTextState extends State<TopicContentText> {
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

    return RichText(
      text: TextSpan(
        style: baseStyle.copyWith(color: baseStyle.color ?? Colors.black87),
        children: _buildSpans(activeStyle),
      ),
    );
  }

  List<InlineSpan> _buildSpans(TextStyle activeStyle) {
    final List<InlineSpan> spans = <InlineSpan>[];
    var start = 0;

    for (final match in _tokenPattern.allMatches(widget.text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: widget.text.substring(start, match.start)));
      }

      final token = match.group(0)!;
      spans.add(
        TextSpan(
          text: token,
          style: activeStyle,
          recognizer: _createRecognizer(token),
        ),
      );
      start = match.end;
    }

    if (start < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(start)));
    }

    return spans;
  }

  TapGestureRecognizer? _createRecognizer(String token) {
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

    if (onTap == null) return null;

    final recognizer = TapGestureRecognizer()
      ..onTap = () {
        final result = onTap?.call();
        if (result is Future<void>) {
          unawaited(result);
        }
      };
    _recognizers.add(recognizer);
    return recognizer;
  }
}
