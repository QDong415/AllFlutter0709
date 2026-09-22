import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 语音条播放喇叭：微信风格黑色喇叭 + 1/2/3 道声波。
class ChatVoicePlayIcon extends StatefulWidget {
  const ChatVoicePlayIcon({
    super.key,
    required this.isRight,
    required this.isPlaying,
  });

  final bool isRight;
  final bool isPlaying;

  @override
  State<ChatVoicePlayIcon> createState() => _ChatVoicePlayIconState();
}

class _ChatVoicePlayIconState extends State<ChatVoicePlayIcon> {
  static const _frameDuration = Duration(milliseconds: 300);
  static const _iconSize = 22.0;

  Timer? _timer;

  /// 0 满波 / 1 仅喇叭 / 2 喇叭+1 波，对齐微信播放循环。
  int _frameIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isPlaying) {
      _frameIndex = 1;
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(covariant ChatVoicePlayIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying == oldWidget.isPlaying) {
      return;
    }
    _timer?.cancel();
    if (widget.isPlaying) {
      _frameIndex = 1;
      _startTimer();
    } else {
      _frameIndex = 0;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(_frameDuration, (_) {
      if (!mounted || !widget.isPlaying) {
        return;
      }
      setState(() {
        _frameIndex = (_frameIndex + 1) % 3;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _arcCount {
    switch (_frameIndex) {
      case 1:
        return 0;
      case 2:
        return 1;
      default:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _iconSize,
      height: _iconSize,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(widget.isRight ? 1 : -1, 1, 1),
        child: CustomPaint(
          painter: _WechatVoiceWavePainter(arcCount: _arcCount),
        ),
      ),
    );
  }
}

/// 微信语音条喇叭：实心喇叭头 + 两道圆声波，颜色接近微信黑。
class _WechatVoiceWavePainter extends CustomPainter {
  const _WechatVoiceWavePainter({required this.arcCount});

  final int arcCount;

  static const _color = Color(0xFF111111);

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final fillPaint = Paint()
      ..color = _color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final stemLeft = size.width * 0.04;
    final stemRight = size.width * 0.26;
    final coneRight = size.width * 0.46;
    final stemHalfH = size.height * 0.13;
    final coneHalfH = size.height * 0.30;

    final speaker = Path()
      ..moveTo(stemLeft, cy - stemHalfH)
      ..lineTo(stemRight, cy - stemHalfH)
      ..lineTo(coneRight, cy - coneHalfH)
      ..lineTo(coneRight, cy + coneHalfH)
      ..lineTo(stemRight, cy + stemHalfH)
      ..lineTo(stemLeft, cy + stemHalfH)
      ..close();
    canvas.drawPath(speaker, fillPaint);

    if (arcCount <= 0) {
      return;
    }

    final wavePaint = Paint()
      ..color = _color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.105
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final origin = Offset(coneRight - size.width * 0.04, cy);
    const startAngle = -math.pi * 0.28;
    const sweepAngle = math.pi * 0.56;
    for (var i = 0; i < arcCount; i++) {
      final radius = size.width * (0.24 + i * 0.20);
      canvas.drawArc(
        Rect.fromCircle(center: origin, radius: radius),
        startAngle,
        sweepAngle,
        false,
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WechatVoiceWavePainter oldDelegate) {
    return oldDelegate.arcCount != arcCount;
  }
}
