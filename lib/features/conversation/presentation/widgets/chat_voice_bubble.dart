import 'dart:math' as math;

import 'package:all_flutter0709/features/conversation/presentation/models/chat_item.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_bubble_frame.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_bubble_metrics.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_voice_play_icon.dart';
import 'package:flutter/material.dart';

/// 语音条气泡；[isPlaying] 由页面传入。
class ChatVoiceBubble extends StatelessWidget {
  const ChatVoiceBubble({
    super.key,
    required this.item,
    this.isPlaying = false,
    this.isSelected = false,
  });

  final VoiceMessage item;
  final bool isPlaying;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final width = math.max(82.0, math.min(168.0, 64.0 + item.seconds * 16.0));
    final playIcon = ChatVoicePlayIcon(
      isRight: item.isRight,
      isPlaying: isPlaying,
    );

    final bubble = ChatBubbleFrame(
      isRight: item.isRight,
      isSelected: isSelected,
      child: SizedBox(
        width: width,
        height: ChatBubbleMetrics.avatarSize,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: item.isRight
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: item.isRight
                ? [
                    Text(
                      '${item.seconds}"',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.2,
                        color: Color(0xFF191919),
                      ),
                    ),
                    const SizedBox(width: 8),
                    playIcon,
                  ]
                : [
                    playIcon,
                    const SizedBox(width: 8),
                    Text(
                      '${item.seconds}"',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.2,
                        color: Color(0xFF191919),
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );

    if (item.isRight) {
      return bubble;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        bubble,
        Visibility(
          visible: !item.hadPlay && !isPlaying,
          child: const Padding(
            padding: EdgeInsets.only(left: 6, top: 4),
            child: SizedBox(
              width: 8,
              height: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFFFA5151),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
