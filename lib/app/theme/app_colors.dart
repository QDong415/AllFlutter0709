import 'package:flutter/material.dart';

/// 应用统一色板。
///
/// 业务强调色（如点赞橙）与壳层主色分离，避免全局被红覆盖。
abstract final class AppColors {
  /// 品牌主色 / Tab 选中 / 主按钮（QKotlin `red_color`）
  static const Color primary = Color(0xFFFE6766);

  /// 主色按下态（QKotlin `red_press_color`）
  static const Color primaryPressed = Color(0xFFE64C64);

  /// 业务强调色（点赞 / 分享等，Flutter 既有，不跟 QKotlin 壳层主色混用）
  static const Color accent = Color(0xFFF46533);

  /// 导航栏 / 状态栏背景（QKotlin `toolbar_color`）
  static const Color toolbar = Color(0xFFF6F6F6);

  /// 导航栏标题（比 QKotlin `text_black_color` 更深，接近黑）
  static const Color titleText = Color(0xFF333333);

  /// 页面 body / 列表背景（QKotlin 列表实际硬编码）
  static const Color bodyBackground = Color(0xFFF2F2F2);

  /// 分割线（统一中性灰，避免主题 seed 染成粉色）
  static const Color divider = Color(0xFFDFDFDF);

  /// Tab 栏 / 系统导航栏背景
  static const Color tabBarBackground = Color(0xFFFFFFFF);

  /// Tab 未选中（Material BottomNavigation 默认：onSurface @ 60%）
  static const Color tabUnselected = Color(0x99000000);

  /// 纯白
  static const Color white = Color(0xFFFFFFFF);

  /// 纯黑
  static const Color black = Color(0xFF000000);
}
