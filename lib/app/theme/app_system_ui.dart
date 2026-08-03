import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 系统状态栏 / 导航栏样式。
abstract final class AppSystemUi {
  /// 默认（白底导航栏，深色图标），与主 Tab / 普通页一致。
  static const SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: AppColors.tabBarBackground,
    systemNavigationBarDividerColor: AppColors.tabBarBackground,
    systemNavigationBarContrastEnforced: false,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarIconBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  /// 全屏媒体预览（黑底）：底部系统导航栏黑色，图标浅色。
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

  /// 立即应用到系统栏（部分机型仅靠 [AnnotatedRegion] 不可靠）。
  static void apply(SystemUiOverlayStyle style) {
    SystemChrome.setSystemUIOverlayStyle(style);
  }
}

/// 包裹全屏媒体预览：进入时导航栏变黑，离开后恢复默认白底。
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
