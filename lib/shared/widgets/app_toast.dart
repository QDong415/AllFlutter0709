import 'dart:async';

import 'package:flutter/material.dart';

/// 屏幕中间的短提示，淡入淡出并轻微缩放。
class AppToast {
  AppToast._();

  static OverlayEntry? _entry;

  /// 在屏幕中间显示 [message]，约 2 秒后消失。新提示会替换上一条。
  static void show(BuildContext context, String message) {
    final text = message.replaceFirst('Exception: ', '').trim();
    if (text.isEmpty || !context.mounted) {
      return;
    }

    _entry?.remove();
    _entry = null;

    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return _CenterToast(
          message: text,
          onFinished: () {
            if (_entry != entry) {
              return;
            }
            entry.remove();
            _entry = null;
          },
        );
      },
    );
    _entry = entry;
    overlay.insert(entry);
  }
}

/// 居中提示的浮层内容。
class _CenterToast extends StatefulWidget {
  const _CenterToast({required this.message, required this.onFinished});

  final String message;
  final VoidCallback onFinished;

  @override
  State<_CenterToast> createState() => _CenterToastState();
}

class _CenterToastState extends State<_CenterToast>
    with SingleTickerProviderStateMixin {
  static const Duration _hold = Duration(milliseconds: 1600);

  late final AnimationController _controller;
  Timer? _holdTimer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _controller.forward();
    _holdTimer = Timer(_hold, _close);
  }

  Future<void> _close() async {
    if (_closing || !mounted) {
      return;
    }
    _closing = true;
    await _controller.reverse();
    if (!mounted) {
      return;
    }
    widget.onFinished();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return IgnorePointer(
      child: Center(
        child: FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.72,
              ),
              child: Material(
                color: const Color(0xE6333333),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
