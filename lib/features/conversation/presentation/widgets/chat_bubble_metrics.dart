import 'package:flutter/material.dart';

/// 对齐微信 iOS 会话的气泡布局尺寸。
abstract final class ChatBubbleMetrics {
  static const screenPadding = 12.0;
  static const avatarSize = 40.0;
  static const avatarGap = 10.0;
  static const oppositeReserve = 48.0;
  static const messageSpacing = 8.0;
  static const fontSize = 17.0;
  static const lineHeight = 1.3;

  /// 气泡内容最大宽度（屏幕宽减去头像和对侧留白）。
  static double maxBubbleWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width -
        screenPadding -
        avatarSize -
        avatarGap -
        oppositeReserve;
  }
}
