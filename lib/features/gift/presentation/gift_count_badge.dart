import 'package:flutter/material.dart';

/// 礼物数量，用 Buddy 的 `w_x`、`w_0`–`w_9` 拼出来。
///
/// 切图放在 xhdpi，Android 按像素的一半显示，不拉到父布局的 40dp。
/// [markOnRight] 为 true 时数字在左、乘号在右，对齐发出去的消息。
class GiftCountBadge extends StatelessWidget {
  const GiftCountBadge({
    super.key,
    required this.count,
    this.markOnRight = false,
  });

  final int count;
  final bool markOnRight;

  /// xhdpi 像素尺寸。逻辑宽高 = 像素 / 2。
  static const _pixelSizeMap = <String, Size>{
    '0': Size(44, 59),
    '1': Size(44, 59),
    '2': Size(45, 57),
    '3': Size(45, 59),
    '4': Size(44, 58),
    '5': Size(45, 59),
    '6': Size(42, 59),
    '7': Size(47, 58),
    '8': Size(45, 59),
    '9': Size(42, 59),
    'x': Size(38, 33),
  };

  @override
  Widget build(BuildContext context) {
    final digits = count.clamp(0, 9999).toString().split('');
    final names = markOnRight ? [...digits, 'x'] : ['x', ...digits];
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (final name in names)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Image.asset(
              'assets/icons/gift/w_$name.png',
              width: (_pixelSizeMap[name] ?? const Size(44, 59)).width / 2,
              height: (_pixelSizeMap[name] ?? const Size(44, 59)).height / 2,
              gaplessPlayback: true,
            ),
          ),
      ],
    );
  }
}
