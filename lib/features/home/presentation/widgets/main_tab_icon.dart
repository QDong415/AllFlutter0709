import 'package:flutter/material.dart';

/// 主 Tab 图标种类，和底栏四个入口一一对应。
enum MainTabIconKind {
  /// 动态
  topic,

  /// 视频
  video,

  /// 聊天
  conversation,

  /// 我的
  me,
}

/// 主 Tab 图标。
///
/// 四个图形共用 24 格、同一线宽、同一外接框（约 3.8–20.2），
/// 几何中心都在格子正中，避免 Material 字形光学尺寸和中心不一致。
class MainTabIcon extends StatelessWidget {
  const MainTabIcon({
    super.key,
    required this.kind,
    this.filled = false,
  });

  /// 画哪一个 Tab。
  final MainTabIconKind kind;

  /// 为 true 时画实心，对应选中态。
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final size = iconTheme.size ?? 24;
    final color = iconTheme.color ?? const Color(0xFF000000);
    return CustomPaint(
      size: Size.square(size),
      painter: _MainTabIconPainter(
        kind: kind,
        filled: filled,
        color: color,
      ),
    );
  }
}

class _MainTabIconPainter extends CustomPainter {
  const _MainTabIconPainter({
    required this.kind,
    required this.filled,
    required this.color,
  });

  final MainTabIconKind kind;
  final bool filled;
  final Color color;

  static const double _strokeWidth = 1.75;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..isAntiAlias = true;
    switch (kind) {
      case MainTabIconKind.topic:
        _paintTopic(canvas, paint);
      case MainTabIconKind.video:
        _paintVideo(canvas, paint);
      case MainTabIconKind.conversation:
        _paintConversation(canvas, paint);
      case MainTabIconKind.me:
        _paintMe(canvas, paint);
    }
  }

  void _paintTopic(Canvas canvas, Paint paint) {
    final house = Path()
      ..moveTo(12, 3.8)
      ..lineTo(20.2, 11)
      ..lineTo(20.2, 20.2)
      ..lineTo(3.8, 20.2)
      ..lineTo(3.8, 11)
      ..close();
    if (filled) {
      house
        ..addRect(const Rect.fromLTRB(9.7, 14.7, 14.3, 20.7))
        ..fillType = PathFillType.evenOdd;
      canvas.drawPath(house, paint);
      return;
    }
    canvas.drawPath(house, paint);
    canvas.drawPath(
      Path()
        ..moveTo(9.7, 20.2)
        ..lineTo(9.7, 14.7)
        ..lineTo(14.3, 14.7)
        ..lineTo(14.3, 20.2),
      paint,
    );
  }

  void _paintVideo(Canvas canvas, Paint paint) {
    final frame = Path()
      ..addRRect(
        RRect.fromLTRBR(3.8, 3.8, 20.2, 20.2, const Radius.circular(4.2)),
      );
    final play = Path()
      ..moveTo(10.35, 8.55)
      ..lineTo(15.85, 12)
      ..lineTo(10.35, 15.45)
      ..close();
    if (filled) {
      frame
        ..addPath(play, Offset.zero)
        ..fillType = PathFillType.evenOdd;
      canvas.drawPath(frame, paint);
      return;
    }
    canvas.drawPath(frame, paint);
    canvas.drawPath(play, paint);
  }

  void _paintConversation(Canvas canvas, Paint paint) {
    const left = 3.8;
    const top = 3.8;
    const right = 20.2;
    const bottom = 16.15;
    const radius = 4.2;
    final bubble = Path()
      ..moveTo(left + radius, top)
      ..lineTo(right - radius, top)
      ..quadraticBezierTo(right, top, right, top + radius)
      ..lineTo(right, bottom - radius)
      ..quadraticBezierTo(right, bottom, right - radius, bottom)
      ..lineTo(10.6, bottom)
      ..lineTo(5.9, 20.2)
      ..lineTo(left + radius, bottom)
      ..quadraticBezierTo(left, bottom, left, bottom - radius)
      ..lineTo(left, top + radius)
      ..quadraticBezierTo(left, top, left + radius, top)
      ..close();
    canvas.drawPath(bubble, paint);
  }

  void _paintMe(Canvas canvas, Paint paint) {
    canvas.drawCircle(const Offset(12, 7.25), 3.35, paint);
    final shoulders = Path()
      ..moveTo(3.8, 20.2)
      ..cubicTo(3.8, 15.15, 7.35, 13.75, 12, 13.75)
      ..cubicTo(16.65, 13.75, 20.2, 15.15, 20.2, 20.2);
    if (filled) {
      shoulders.close();
    }
    canvas.drawPath(shoulders, paint);
  }

  @override
  bool shouldRepaint(covariant _MainTabIconPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.filled != filled ||
        oldDelegate.color != color;
  }
}
