import 'dart:math' as math;

import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// AI 生图等待动效：粒子轨道、脉冲光环与阶段文案。
class AiGenerationAnimation extends StatefulWidget {
  const AiGenerationAnimation({
    super.key,
    required this.title,
    required this.detail,
  });

  final String title;
  final String detail;

  @override
  State<AiGenerationAnimation> createState() => _AiGenerationAnimationState();
}

class _AiGenerationAnimationState extends State<AiGenerationAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0.35;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.center,
            child: SizedBox.square(
              dimension: 230,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  painter: _AiParticlePainter(progress: _controller.value),
                  child: Center(
                    child: Container(
                      width: 88,
                      height: 112,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(44),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.32),
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primary,
                        size: 42,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.titleText,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Text(
                widget.detail,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiParticlePainter extends CustomPainter {
  const _AiParticlePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final pulse = 0.5 + 0.5 * math.sin(progress * math.pi * 2);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = AppColors.primary.withValues(alpha: 0.16 + pulse * 0.14);
    canvas.drawCircle(center, 64 + pulse * 5, ringPaint);
    canvas.drawCircle(center, 88 - pulse * 4, ringPaint);

    for (var index = 0; index < 34; index++) {
      final baseAngle = index * 2.399963;
      final speed = 0.35 + (index % 5) * 0.08;
      final angle = baseAngle + progress * math.pi * 2 * speed;
      final radius = 54.0 + (index * 19 % 58);
      final twinkle =
          0.35 + 0.65 * ((math.sin(progress * math.pi * 4 + index) + 1) / 2);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final paint = Paint()
        ..color = AppColors.primary.withValues(alpha: 0.16 + twinkle * 0.48);
      canvas.drawCircle(point, 1.2 + (index % 3) * 0.75, paint);
    }

    final scanY = 66 + progress * 98;
    final scanPaint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primary.withValues(alpha: 0.32);
    canvas.drawLine(
      Offset(center.dx - 31, scanY),
      Offset(center.dx + 31, scanY),
      scanPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AiParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
