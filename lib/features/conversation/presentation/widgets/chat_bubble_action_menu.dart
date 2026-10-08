import 'package:flutter/material.dart';

/// 气泡长按菜单：贴着气泡显示「复制」「撤回」「删除」。
class ChatBubbleActionMenu extends StatelessWidget {
  const ChatBubbleActionMenu({
    super.key,
    required this.anchorRect,
    required this.onCopy,
    required this.onDelete,
    required this.onDismiss,
    this.onRecall,
  });

  /// 相对外层 Stack 的气泡矩形。
  final Rect anchorRect;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final VoidCallback onDismiss;

  /// 仅自己发出、且还在撤回时限内的消息会传入。
  final VoidCallback? onRecall;

  static const double _itemWidth = 66;
  static const double _menuHeight = 42;
  static const double _arrowSize = 7;
  static const double _gap = 6;
  static const Color _background = Color(0xE64C4C4C);

  double get _menuWidth => onRecall == null ? _itemWidth * 2 : _itemWidth * 3;

  @override
  Widget build(BuildContext context) {
    final menuWidth = _menuWidth;
    return LayoutBuilder(
      builder: (context, constraints) {
        final showAbove = anchorRect.top >= _menuHeight + _arrowSize + _gap + 8;
        final menuTop = showAbove
            ? anchorRect.top - _gap - _arrowSize - _menuHeight
            : anchorRect.bottom + _gap;
        var menuLeft = anchorRect.center.dx - menuWidth / 2;
        final maxLeft = constraints.maxWidth - menuWidth - 8;
        menuLeft = menuLeft.clamp(8.0, maxLeft < 8 ? 8.0 : maxLeft);
        final arrowLeft = (anchorRect.center.dx - menuLeft - _arrowSize).clamp(
          16.0,
          menuWidth - _arrowSize - 16,
        );

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: onDismiss,
              ),
            ),
            Positioned(
              left: menuLeft,
              top: menuTop,
              width: menuWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!showAbove)
                    _Arrow(left: arrowLeft, pointUp: true, color: _background),
                  _MenuBar(
                    onCopy: onCopy,
                    onDelete: onDelete,
                    onRecall: onRecall,
                  ),
                  if (showAbove)
                    _Arrow(left: arrowLeft, pointUp: false, color: _background),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MenuBar extends StatelessWidget {
  const _MenuBar({required this.onCopy, required this.onDelete, this.onRecall});

  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final VoidCallback? onRecall;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ChatBubbleActionMenu._background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: SizedBox(
        height: ChatBubbleActionMenu._menuHeight,
        child: Row(
          children: [
            _MenuItem(label: '复制', onTap: onCopy),
            const _MenuDivider(),
            if (onRecall != null) ...[
              _MenuItem(label: '撤回', onTap: onRecall!),
              const _MenuDivider(),
            ],
            _MenuItem(label: '删除', onTap: onDelete),
          ],
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0x33FFFFFF),
      child: SizedBox(width: 1, height: 18),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({
    required this.left,
    required this.pointUp,
    required this.color,
  });

  final double left;
  final bool pointUp;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(left: left),
        child: CustomPaint(
          size: const Size(
            ChatBubbleActionMenu._arrowSize * 2,
            ChatBubbleActionMenu._arrowSize,
          ),
          painter: _ArrowPainter(pointUp: pointUp, color: color),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.pointUp, required this.color});

  final bool pointUp;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointUp) {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height);
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0);
    }
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) {
    return oldDelegate.pointUp != pointUp || oldDelegate.color != color;
  }
}
