import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/app/theme/app_dimens.dart';
import 'package:all_flutter0709/app/theme/app_palette.dart';
import 'package:all_flutter0709/app/theme/app_system_ui.dart';
import 'package:all_flutter0709/app/theme/app_typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:swift_transitions/swift_transitions.dart';

/// 用壳层色板组装应用主题。
///
/// Material 的 [Brightness] 固定为浅色。业务页还有大量写死的深色字和白卡片，
/// 若把整棵主题切成 dark，默认文字会变成浅色，铺在白卡片上就看不见。
/// 暗黑只通过 [AppPalette] 改导航栏、Tab 和设置页。
abstract final class AppTheme {
  /// 组装当前明暗对应的 [ThemeData]。
  static ThemeData build(AppPalette palette) {
    return AppTypography.decorateTheme(
      ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.bodyBackground,
        ),
        scaffoldBackgroundColor: AppColors.bodyBackground,
        // Android 转场会在新旧页之间铺一层 surface。主题亮度固定浅色，
        // 这层默认是浅灰，黑夜模式下每次 push/pop 都会闪白。
        pageTransitionsTheme: PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: PredictiveBackPageTransitionsBuilder(
              fallbackColor: palette.bodyBackground,
            ),
            TargetPlatform.iOS: const SwiftPageTransitionsBuilder(),
            TargetPlatform.macOS: const CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: ZoomPageTransitionsBuilder(
              backgroundColor: palette.bodyBackground,
            ),
            TargetPlatform.windows: ZoomPageTransitionsBuilder(
              backgroundColor: palette.bodyBackground,
            ),
            TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(
              backgroundColor: palette.bodyBackground,
            ),
          },
        ),
        extensions: <ThemeExtension<dynamic>>[palette],
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: palette.toolbar,
          foregroundColor: palette.titleText,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          toolbarHeight: AppDimens.toolbarHeight,
          titleTextStyle: TextStyle(
            color: palette.titleText,
            fontSize: AppDimens.toolbarTitleSize,
            fontWeight: FontWeight.w400,
          ),
          iconTheme: IconThemeData(color: palette.titleText),
          actionsIconTheme: IconThemeData(color: palette.titleText),
          systemOverlayStyle: AppSystemUi.overlayForToolbar(palette.brightness),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: palette.tabBarBackground,
          selectedItemColor: palette.primary,
          unselectedItemColor: palette.tabUnselected,
          selectedIconTheme: IconThemeData(color: palette.primary, size: 24),
          unselectedIconTheme: IconThemeData(
            color: palette.tabUnselected,
            size: 24,
          ),
          selectedLabelStyle: const TextStyle(fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: AppDimens.dividerThickness,
          space: AppDimens.dividerThickness,
        ),
      ),
    );
  }
}
