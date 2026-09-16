import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// iOS 系统中文字体校正：指定 PingFang SC、把 Regular 提到 Medium，并缩小字号。
///
/// 只指定字体族不够：iOS 本来就会用 PingFang，Regular 仍然偏细。
/// 同一 `fontSize` 在 PingFang 上的视觉尺寸也比 Android 更大。
abstract final class AppTypography {
  static const String _iosFontFamily = 'PingFang SC';
  static const List<String> _iosFontFamilyFallback = <String>[_iosFontFamily];

  /// iOS 相对 Android 的额外文字缩放，保留系统「文字大小」设置。
  ///
  /// 0.88 约等于把 18 收到 16。
  static const double iosTextScaleFactor = 0.88;

  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// 仅 iOS 校正主题字体和字重；Android 原样返回。
  static ThemeData decorateTheme(ThemeData theme) {
    if (!_isIOS) {
      return theme;
    }
    return theme.copyWith(
      textTheme: _adjustTextTheme(theme.textTheme),
      primaryTextTheme: _adjustTextTheme(theme.primaryTextTheme),
      appBarTheme: theme.appBarTheme.copyWith(
        titleTextStyle: theme.appBarTheme.titleTextStyle == null
            ? null
            : _applyIosFont(theme.appBarTheme.titleTextStyle!),
      ),
      bottomNavigationBarTheme: theme.bottomNavigationBarTheme.copyWith(
        selectedLabelStyle: _applyIosStyle(
          theme.bottomNavigationBarTheme.selectedLabelStyle,
        ),
        unselectedLabelStyle: _applyIosStyle(
          theme.bottomNavigationBarTheme.unselectedLabelStyle,
        ),
      ),
    );
  }

  /// 在 iOS 上缩小文字，并保留系统辅助功能缩放。
  static Widget wrapWithIosTextScale(BuildContext context, Widget? child) {
    final content = child ?? const SizedBox.shrink();
    if (!_isIOS) {
      return content;
    }
    final mediaQuery = MediaQuery.of(context);
    final currentScale = mediaQuery.textScaler.scale(14) / 14;
    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: TextScaler.linear(currentScale * iosTextScaleFactor),
      ),
      child: content,
    );
  }

  static TextStyle? _applyIosStyle(TextStyle? style) {
    if (style == null) {
      return null;
    }
    return _applyIosFont(style);
  }

  static TextStyle _applyIosFont(TextStyle style) {
    final weight = style.fontWeight;
    return style.copyWith(
      fontFamily: style.fontFamily ?? _iosFontFamily,
      fontFamilyFallback: style.fontFamilyFallback ?? _iosFontFamilyFallback,
      fontWeight: (weight == null || weight.index <= FontWeight.w400.index)
          ? FontWeight.w500
          : weight,
    );
  }

  static TextTheme _adjustTextTheme(TextTheme textTheme) {
    return TextTheme(
      displayLarge: _applyIosStyle(textTheme.displayLarge),
      displayMedium: _applyIosStyle(textTheme.displayMedium),
      displaySmall: _applyIosStyle(textTheme.displaySmall),
      headlineLarge: _applyIosStyle(textTheme.headlineLarge),
      headlineMedium: _applyIosStyle(textTheme.headlineMedium),
      headlineSmall: _applyIosStyle(textTheme.headlineSmall),
      titleLarge: _applyIosStyle(textTheme.titleLarge),
      titleMedium: _applyIosStyle(textTheme.titleMedium),
      titleSmall: _applyIosStyle(textTheme.titleSmall),
      bodyLarge: _applyIosStyle(textTheme.bodyLarge),
      bodyMedium: _applyIosStyle(textTheme.bodyMedium),
      bodySmall: _applyIosStyle(textTheme.bodySmall),
      labelLarge: _applyIosStyle(textTheme.labelLarge),
      labelMedium: _applyIosStyle(textTheme.labelMedium),
      labelSmall: _applyIosStyle(textTheme.labelSmall),
    );
  }
}
