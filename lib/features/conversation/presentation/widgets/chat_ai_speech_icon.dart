import 'dart:async';
import 'dart:math' as math;

import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// 文字气泡右下角的朗读按钮：浅色圆钮，播放时声波轻轻起伏。
class ChatAiSpeechIcon extends StatefulWidget {
  const ChatAiSpeechIcon({
    super.key,
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
  });

  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  State<ChatAiSpeechIcon> createState() => _ChatAiSpeechIconState();
}

class _ChatAiSpeechIconState extends State<ChatAiSpeechIcon> {
  static const _buttonSize = 22.0;
  Timer? _timer;
  int _wave = 1;

  @override
  void initState() {
    super.initState();
    if (widget.isPlaying) {
      _startWave();
    }
  }

  @override
  void didUpdateWidget(covariant ChatAiSpeechIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying == oldWidget.isPlaying) {
      return;
    }
    _timer?.cancel();
    if (widget.isPlaying) {
      _wave = 1;
      _startWave();
    }
  }

  void _startWave() {
    _timer = Timer.periodic(const Duration(milliseconds: 280), (_) {
      if (!mounted || !widget.isPlaying) {
        return;
      }
      setState(() {
        _wave = _wave == 1 ? 2 : 1;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.isPlaying;
    final color = active ? AppColors.primary : const Color(0xFF8E8E8E);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // loading 时也保留点击识别，避免事件落到外层消息区而收起键盘。
      onTap: widget.isLoading ? () {} : widget.onTap,
      child: SizedBox(
        width: 30,
        height: 30,
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Container(
            width: _buttonSize,
            height: _buttonSize,
            decoration: BoxDecoration(
              color: active ? const Color(0xFFFFF1F0) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: active
                    ? const Color(0xFFFFC9C6)
                    : const Color(0xFFE4E4E4),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: widget.isLoading
                ? SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.4,
                      color: color,
                    ),
                  )
                : CustomPaint(
                    size: const Size(12, 12),
                    painter: _SpeechMarkPainter(
                      color: color,
                      waves: active ? _wave : 1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// 细线喇叭。静止时一道声波，播放时在一道和两道之间切换。
class _SpeechMarkPainter extends CustomPainter {
  const _SpeechMarkPainter({required this.color, required this.waves});

  final Color color;
  final int waves;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final body = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final speaker = Path()
      ..moveTo(size.width * 0.02, cy - size.height * 0.12)
      ..lineTo(size.width * 0.28, cy - size.height * 0.12)
      ..lineTo(size.width * 0.48, cy - size.height * 0.34)
      ..lineTo(size.width * 0.48, cy + size.height * 0.34)
      ..lineTo(size.width * 0.28, cy + size.height * 0.12)
      ..lineTo(size.width * 0.02, cy + size.height * 0.12)
      ..close();
    canvas.drawPath(speaker, body);

    final wave = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    final origin = Offset(size.width * 0.46, cy);
    for (var index = 0; index < waves; index++) {
      final radius = size.width * (0.28 + index * 0.24);
      canvas.drawArc(
        Rect.fromCircle(center: origin, radius: radius),
        -math.pi / 3.4,
        math.pi / 1.7,
        false,
        wave,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpeechMarkPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.waves != waves;
  }
}
