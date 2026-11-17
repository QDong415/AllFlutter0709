import 'package:flutter/material.dart';

/// 录音音量条：高度随 [amplitude]（record 包 dBFS）变化，不撑开父布局。
class RecordingAmplitudeBars extends StatelessWidget {
  const RecordingAmplitudeBars({
    super.key,
    required this.amplitude,
    required this.barColor,
    this.barCount = 7,
    this.waveHeight = 36,
    this.barWidth = 4,
  });

  final double amplitude;
  final Color barColor;
  final int barCount;
  final double waveHeight;
  final double barWidth;

  static const double _barMinHeight = 4;

  /// record 包振幅为 dBFS。人声常见区间约 -42~-10。
  static double normalizeAmplitude(double db) {
    const minDb = -42.0;
    const maxDb = -10.0;
    final linear = ((db - minDb) / (maxDb - minDb)).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(linear);
  }

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeAmplitude(amplitude);
    final center = (barCount - 1) / 2;

    return SizedBox(
      height: waveHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(barCount, (index) {
          final dist = (index - center).abs();
          final stagger = (1.0 - dist * 0.14).clamp(0.55, 1.0);
          final factor = (normalized * stagger).clamp(0.1, 1.0);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOut,
            width: barWidth,
            height: _barMinHeight + (waveHeight - _barMinHeight) * factor,
            margin: EdgeInsets.symmetric(horizontal: barWidth * 0.6),
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(99),
            ),
          );
        }),
      ),
    );
  }
}