/// 应用统一尺寸，对齐 QKotlin `dimens.xml` 壳层数值。
abstract final class AppDimens {
  /// 导航栏高度（QKotlin `toolbar_height` = 45dp）
  static const double toolbarHeight = 45;

  /// 底部 Tab 高度（QKotlin `bottom_bar_height` = 56dp）
  static const double bottomBarHeight = 56;

  /// 导航栏标题字号（QKotlin `ToolTitleStyle` = 17sp）
  static const double toolbarTitleSize = 17;

  /// 分割线高度 / 粗细（对齐 Android 0.5dp）
  static const double dividerThickness = 0.5;
}
