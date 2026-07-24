import 'package:flutter/material.dart';

/// 壳层轻阴影，与评论底栏同一套层次感。
abstract final class AppShadows {
  static const Color _color = Color(0x18000000);
  static const double _blurRadius = 14;

  /// 底栏向上投影（TabBar / 评论输入栏）
  static const List<BoxShadow> upward = [
    BoxShadow(
      color: _color,
      blurRadius: _blurRadius,
      offset: Offset(0, -3),
    ),
  ];

  /// 顶栏向下投影（导航栏）
  static const List<BoxShadow> downward = [
    BoxShadow(
      color: _color,
      blurRadius: _blurRadius,
      offset: Offset(0, 3),
    ),
  ];
}
