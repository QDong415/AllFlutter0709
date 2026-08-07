import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 系统状态栏 / 导航栏样式（全应用唯一来源）。
///
/// 不要直接使用 [SystemUiOverlayStyle.light] / [SystemUiOverlayStyle.dark]，
/// 它们会把 `systemNavigationBarColor` 设成黑色，小米等机型底部指示区会变黑。
abstract final class AppSystemUi {
  /// 默认：透明系统导航栏 + 深色图标（配合液态玻璃底栏 / edge-to-edge）。
  static const SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarIconBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  /// 全屏媒体预览：黑底导航栏 + 浅色图标。
  static const SystemUiOverlayStyle fullscreenMediaOverlayStyle =
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.black,
        systemNavigationBarDividerColor: AppColors.black,
        systemNavigationBarContrastEnforced: false,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      );

  /// 在 [overlayStyle]（透明导航栏）基础上，只切换状态栏图标明暗。
  ///
  /// 用于个人主页 / 视频详情等「顶栏随滚动变实色」的场景。
  static SystemUiOverlayStyle overlayStyleWithStatusBarIcons({
    required bool darkIcons,
  }) {
    return overlayStyle.copyWith(
      statusBarIconBrightness: darkIcons ? Brightness.dark : Brightness.light,
      statusBarBrightness: darkIcons ? Brightness.light : Brightness.dark,
    );
  }

  /// 立即应用到系统栏（部分机型仅靠 [AnnotatedRegion] 不可靠）。
  static void apply(SystemUiOverlayStyle style) {
    SystemChrome.setSystemUIOverlayStyle(style);
  }
}

/// 包裹全屏媒体预览：进入时导航栏变黑，离开后恢复默认透明导航栏。
class FullscreenMediaSystemUi extends StatefulWidget {
  const FullscreenMediaSystemUi({super.key, required this.child});

  final Widget child;

  @override
  State<FullscreenMediaSystemUi> createState() =>
      _FullscreenMediaSystemUiState();
}

class _FullscreenMediaSystemUiState extends State<FullscreenMediaSystemUi> {
  @override
  void initState() {
    super.initState();
    AppSystemUi.apply(AppSystemUi.fullscreenMediaOverlayStyle);
  }

  @override
  void dispose() {
    AppSystemUi.apply(AppSystemUi.overlayStyle);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.fullscreenMediaOverlayStyle,
      child: widget.child,
    );
  }
}
