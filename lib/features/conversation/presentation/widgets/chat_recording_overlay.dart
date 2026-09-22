import 'package:flutter/material.dart';

/// 聊天录音中遮罩：振幅条、时长与取消提示。
class ChatRecordingOverlay extends StatelessWidget {
  const ChatRecordingOverlay({
    super.key,
    required this.isCancelling,
    required this.seconds,
    required this.amplitude,
  });

  final bool isCancelling;
  final int seconds;
  final double amplitude;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 156,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: BoxDecoration(
          color: isCancelling
              ? const Color(0xCCB3261E)
              : const Color(0xB2000000),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCancelling ? Icons.delete_outline_rounded : Icons.mic_rounded,
              size: 42,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            _ChatRecordingWaveView(amplitude: amplitude),
            const SizedBox(height: 12),
            Text(
              '$seconds"',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCancelling ? '松开手指，取消发送' : '手指上滑，取消发送',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// 固定高度的音浪条；总高度按最大音量占位，避免撑开浮窗。
class _ChatRecordingWaveView extends StatelessWidget {
  const _ChatRecordingWaveView({required this.amplitude});

  final double amplitude;

  /// 音浪区域总高度（最大音量时条高）。
  static const double _waveHeight = 32;

  static const double _barMinHeight = 4;
  static const int _barCount = 5;

  /// record 包振幅为 dBFS。人声常见区间约 -42~-10，收窄后大声更容易顶满。
  static double _normalizeAmplitude(double db) {
    const minDb = -42.0;
    const maxDb = -10.0;
    final linear = ((db - minDb) / (maxDb - minDb)).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(linear);
  }

  @override
  Widget build(BuildContext context) {
    final normalized = _normalizeAmplitude(amplitude);

    return SizedBox(
      height: _waveHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_barCount, (index) {
          final stagger = index == 0 || index == _barCount - 1
              ? 0.62
              : (index == 1 || index == _barCount - 2 ? 0.86 : 1.0);
          final factor = (normalized * stagger).clamp(0.12, 1.0);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOut,
            width: 5,
            height: _barMinHeight + (_waveHeight - _barMinHeight) * factor,
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(99),
            ),
          );
        }),
      ),
    );
  }
}
