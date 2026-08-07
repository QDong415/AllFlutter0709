/// 应用统一尺寸。
abstract final class AppDimens {
  /// 导航栏高度（QKotlin `toolbar_height` = 45dp）
  static const double toolbarHeight = 45;

  /// 底部 Tab 高度（QKotlin `bottom_bar_height` = 56dp）
  static const double bottomBarHeight = 56;

  /// 液态玻璃底栏内容留白（`GlassTabBar` 默认 barHeight 64 + verticalPadding×2 40）。
  ///
  /// 主壳 `extendBody` 后，各 Tab 列表需加此底部 padding，避免末项被挡住。
  static const double glassTabBarContentInset = 104;

  /// 导航栏标题字号（QKotlin `ToolTitleStyle` = 17sp）
  static const double toolbarTitleSize = 17;

  /// 分割线高度 / 粗细（对齐 Android 0.5dp）
  static const double dividerThickness = 0.5;
}
