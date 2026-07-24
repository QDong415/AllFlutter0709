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
    final normalized = ((amplitude + 45) / 45).clamp(0.0, 1.0);

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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(4, (index) {
                final factor = (normalized * (0.5 + index * 0.18)).clamp(
                  0.2,
                  1.0,
                );
                return Container(
                  width: 6,
                  height: 10 + 18 * factor,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
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
