import 'dart:async';

import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/bridge/native_bridge.dart';
import 'package:all_flutter0709/core/bridge/native_methods.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 系统状态栏 / 导航栏样式（全应用唯一来源）。
///
/// 不要直接使用 [SystemUiOverlayStyle.light] / [SystemUiOverlayStyle.dark]，
/// 它们在小米上会把导航栏对比度强制打开。导航栏用明确的白/黑，图标跟随明暗。
abstract final class AppSystemUi {
  /// 当前界面明暗。全屏预览退出时用它恢复系统栏。
  static Brightness themeBrightness = Brightness.light;

  /// 浅色默认：白底导航栏 + 深色图标。深色由 [overlayForToolbar] 覆盖。
  static const SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Color(0xFFFFFFFF),
    systemNavigationBarDividerColor: Color(0xFFFFFFFF),
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

  /// 浅色：白底导航栏、深色状态栏文字。黑夜：黑底导航栏、浅色状态栏文字。
  static SystemUiOverlayStyle overlayForToolbar(Brightness toolbarBrightness) {
    final dark = toolbarBrightness == Brightness.dark;
    final navigationBar = dark
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
    return overlayStyle.copyWith(
      systemNavigationBarColor: navigationBar,
      systemNavigationBarDividerColor: navigationBar,
      systemNavigationBarIconBrightness: dark
          ? Brightness.light
          : Brightness.dark,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
    );
  }

  /// 导航栏跟 [navigationBar] 走，状态栏图标可单独指定。
  ///
  /// 个人主页封面、视频详情这类顶栏会随滚动变色，状态栏图标不能只看整页明暗。
  static SystemUiOverlayStyle overlayStyleWithStatusBarIcons({
    required bool darkIcons,
    Brightness navigationBar = Brightness.light,
  }) {
    final darkNavigation = navigationBar == Brightness.dark;
    final navigationColor = darkNavigation
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
    return overlayStyle.copyWith(
      systemNavigationBarColor: navigationColor,
      systemNavigationBarDividerColor: navigationColor,
      systemNavigationBarIconBrightness: darkNavigation
          ? Brightness.light
          : Brightness.dark,
      statusBarIconBrightness: darkIcons ? Brightness.dark : Brightness.light,
      statusBarBrightness: darkIcons ? Brightness.light : Brightness.dark,
    );
  }

  static int? _appliedSignature;

  /// 安卓窗口底色。转场露出窗口时不能是启动页的白底。
  static Color _windowBackground = AppColors.bodyBackground;

  /// 立即应用到系统栏。小米会在回到前台时重刷系统栏，所以同时写给原生。
  ///
  /// [windowBackground] 只在明暗切换时传入。之后的调用继续用上次的底色。
  static void apply(SystemUiOverlayStyle style, {Color? windowBackground}) {
    if (windowBackground != null) {
      _windowBackground = windowBackground;
    }
    final signature = Object.hash(
      style.statusBarIconBrightness,
      style.statusBarBrightness,
      style.systemNavigationBarColor,
      style.systemNavigationBarIconBrightness,
      style.statusBarColor,
      _windowBackground.toARGB32(),
    );
    if (signature == _appliedSignature) {
      return;
    }
    _appliedSignature = signature;
    SystemChrome.setSystemUIOverlayStyle(style);
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    final navigationColor =
        style.systemNavigationBarColor ?? const Color(0xFFFFFFFF);
    unawaited(
      NativeBridge.instance
          .call<bool>(
            api: NativeApis.setSystemBars,
            args: <String, dynamic>{
              'lightStatusBars':
                  style.statusBarIconBrightness != Brightness.light,
              'lightNavigationBars':
                  style.systemNavigationBarIconBrightness != Brightness.light,
              'navigationBarColor': navigationColor.toARGB32(),
              'windowBackgroundColor': _windowBackground.toARGB32(),
            },
          )
          .catchError((Object _) {
            _appliedSignature = null;
            return false;
          }),
    );
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
    // 由退场后重新露出的页面通过 AnnotatedRegion 恢复自己的系统栏样式。
    // 这里主动套用全局默认值会与下层页面短暂冲突，导致状态栏白条闪烁。
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
