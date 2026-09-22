import 'package:all_flutter0709/features/conversation/presentation/models/chat_item.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_bubble_frame.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_bubble_metrics.dart';
import 'package:flutter/material.dart';

/// 文本气泡内容；长按菜单由行壳统一接收。
class ChatTextBubble extends StatelessWidget {
  const ChatTextBubble({
    super.key,
    required this.item,
    this.isSelected = false,
  });

  final TextMessage item;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final segments = item.text.split('\n');

    for (var index = 0; index < segments.length; index++) {
      final segment = segments[index];
      final isUrl =
          segment.startsWith('http://') || segment.startsWith('https://');
      spans.add(
        TextSpan(
          text: segment,
          style: TextStyle(
            color: isUrl ? const Color(0xFF576B95) : const Color(0xFF191919),
            decoration: isUrl ? TextDecoration.underline : TextDecoration.none,
            decorationColor: const Color(0xFF576B95),
          ),
        ),
      );
      if (index != segments.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return ChatBubbleFrame(
      isRight: item.isRight,
      isSelected: isSelected,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ChatBubbleMetrics.maxBubbleWidth(context),
          minHeight: 40,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Text.rich(
            TextSpan(children: spans),
            textWidthBasis: TextWidthBasis.longestLine,
            style: const TextStyle(
              fontSize: ChatBubbleMetrics.fontSize,
              height: ChatBubbleMetrics.lineHeight,
              color: Color(0xFF191919),
              leadingDistribution: TextLeadingDistribution.even,
            ),
            strutStyle: const StrutStyle(
              fontSize: ChatBubbleMetrics.fontSize,
              height: ChatBubbleMetrics.lineHeight,
              leadingDistribution: TextLeadingDistribution.even,
            ),
          ),
        ),
      ),
    );
  }
}
