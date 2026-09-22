import 'package:flutter/material.dart';

/// 文本 / 语音气泡外壳：底色、圆角、小尾巴；[isSelected] 给长按高亮。
class ChatBubbleFrame extends StatelessWidget {
  const ChatBubbleFrame({
    super.key,
    required this.isRight,
    required this.child,
    this.isSelected = false,
  });

  final bool isRight;
  final Widget child;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final baseColor = isRight ? const Color(0xFF95EC69) : Colors.white;
    final bubbleColor = isSelected
        ? Color.alphaBlend(const Color(0x33000000), baseColor)
        : baseColor;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: child,
        ),
        Positioned(
          top: 12,
          left: isRight ? null : -5,
          right: isRight ? -5 : null,
          child: _BubbleTail(color: bubbleColor, isRight: isRight),
        ),
      ],
    );
  }
}

class _BubbleTail extends StatelessWidget {
  const _BubbleTail({required this.color, required this.isRight});

  final Color color;
  final bool isRight;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(8, 12),
      painter: _BubbleTailPainter(color: color, isRight: isRight),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter({required this.color, required this.isRight});

  final Color color;
  final bool isRight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    if (isRight) {
      path
        ..moveTo(0, 1)
        ..quadraticBezierTo(
          size.width * 0.2,
          size.height * 0.15,
          size.width,
          size.height * 0.2,
        )
        ..lineTo(size.width * 0.05, size.height)
        ..close();
    } else {
      path
        ..moveTo(size.width, 1)
        ..quadraticBezierTo(
          size.width * 0.8,
          size.height * 0.15,
          0,
          size.height * 0.2,
        )
        ..lineTo(size.width * 0.95, size.height)
        ..close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isRight != isRight;
  }
}
