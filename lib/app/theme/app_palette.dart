import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// 随明暗切换的语义色。
///
/// 浅色与现有界面一致。深色取自 iOS `Images.xcassets/Color`。
/// 压在品牌色或图片上的白字继续用 [AppColors.white]，不要换成 [card]。
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.toolbar,
    required this.titleText,
    required this.bodyBackground,
    required this.divider,
    required this.tabBarBackground,
    required this.tabUnselected,
    required this.card,
    required this.secondaryText,
    required this.chevron,
    required this.bodyText,
    required this.nameText,
    required this.ink,
    required this.plainBackground,
    required this.chatBackground,
    required this.inputBackground,
    required this.inputExtendBackground,
    required this.pressed,
  });

  /// 浅色壳层，数值与 [AppColors] 对齐。
  static const light = AppPalette(
    brightness: Brightness.light,
    primary: AppColors.primary,
    toolbar: AppColors.toolbar,
    titleText: AppColors.titleText,
    bodyBackground: AppColors.bodyBackground,
    divider: AppColors.divider,
    tabBarBackground: AppColors.tabBarBackground,
    tabUnselected: AppColors.tabUnselected,
    card: AppColors.white,
    secondaryText: Color(0xFF999999),
    chevron: Color(0xFFC8C8C8),
    bodyText: Color(0xFF5B5B5B),
    nameText: Color(0xFF304F84),
    ink: AppColors.black,
    plainBackground: AppColors.white,
    chatBackground: Color(0xFFEDEDED),
    inputBackground: AppColors.white,
    inputExtendBackground: Color(0xFFF1F1F1),
    pressed: Color(0xFFF2F2F2),
  );

  /// 深色壳层。注释里的名字对应 iOS colorset。
  static const dark = AppPalette(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    // input_gray_bg
    toolbar: Color(0xFF1D1D1C),
    // black_white
    titleText: Color(0xFFF4F4F4),
    // background
    bodyBackground: Color(0xFF353535),
    // border223
    divider: Color(0xFF353431),
    tabBarBackground: Color(0xFF1D1D1C),
    // text_gray
    tabUnselected: Color(0xFFC4C4C4),
    // cell
    card: Color(0xFF3F3F3F),
    secondaryText: Color(0xFFC4C4C4),
    chevron: Color(0xFFC4C4C4),
    // text_black_gray
    bodyText: Color(0xFFC4C4C4),
    // name
    nameText: Color(0xFF7E8AA9),
    // black_gray
    ink: Color(0xFFC4C4C4),
    // 具名 white
    plainBackground: Color(0xFF353535),
    // gray
    chatBackground: Color(0xFF272727),
    // input
    inputBackground: Color(0xFF252727),
    // input_extend_bg
    inputExtendBackground: Color(0xFF1F1F1F),
    pressed: Color(0xFF4A4A4A),
  );

  /// 当前明暗。
  final Brightness brightness;

  /// 品牌主色。
  final Color primary;

  /// 导航栏背景。
  final Color toolbar;

  /// 导航栏标题 / 壳层主文字。
  final Color titleText;

  /// 页面底。
  final Color bodyBackground;

  /// 壳层分割线。
  final Color divider;

  /// Tab 栏底。
  final Color tabBarBackground;

  /// Tab 未选中。
  final Color tabUnselected;

  /// 列表行 / 设置行表面。
  final Color card;

  /// 行内次要文字。
  final Color secondaryText;

  /// 行尾箭头。
  final Color chevron;

  /// 列表正文（iOS `text_black_gray`）。
  final Color bodyText;

  /// 动态昵称。深色取 iOS `name`。
  final Color nameText;

  /// 输入文字（iOS `black_gray`）。
  final Color ink;

  /// 白底整页（iOS 具名 `white`）。
  final Color plainBackground;

  /// 聊天页底（iOS `gray`）。
  final Color chatBackground;

  /// 输入框底（iOS `input`）。
  final Color inputBackground;

  /// 输入扩展面板底（iOS `input_extend_bg`）。
  final Color inputExtendBackground;

  /// 列表按下态。
  final Color pressed;

  /// 按明暗取色板。
  static AppPalette forBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }

  /// 当前主题色板。未挂载时退回浅色。
  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ?? light;
  }

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? primary,
    Color? toolbar,
    Color? titleText,
    Color? bodyBackground,
    Color? divider,
    Color? tabBarBackground,
    Color? tabUnselected,
    Color? card,
    Color? secondaryText,
    Color? chevron,
    Color? bodyText,
    Color? nameText,
    Color? ink,
    Color? plainBackground,
    Color? chatBackground,
    Color? inputBackground,
    Color? inputExtendBackground,
    Color? pressed,
  }) {
    return AppPalette(
      brightness: brightness ?? this.brightness,
      primary: primary ?? this.primary,
      toolbar: toolbar ?? this.toolbar,
      titleText: titleText ?? this.titleText,
      bodyBackground: bodyBackground ?? this.bodyBackground,
      divider: divider ?? this.divider,
      tabBarBackground: tabBarBackground ?? this.tabBarBackground,
      tabUnselected: tabUnselected ?? this.tabUnselected,
      card: card ?? this.card,
      secondaryText: secondaryText ?? this.secondaryText,
      chevron: chevron ?? this.chevron,
      bodyText: bodyText ?? this.bodyText,
      nameText: nameText ?? this.nameText,
      ink: ink ?? this.ink,
      plainBackground: plainBackground ?? this.plainBackground,
      chatBackground: chatBackground ?? this.chatBackground,
      inputBackground: inputBackground ?? this.inputBackground,
      inputExtendBackground:
          inputExtendBackground ?? this.inputExtendBackground,
      pressed: pressed ?? this.pressed,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      primary: Color.lerp(primary, other.primary, t)!,
      toolbar: Color.lerp(toolbar, other.toolbar, t)!,
      titleText: Color.lerp(titleText, other.titleText, t)!,
      bodyBackground: Color.lerp(bodyBackground, other.bodyBackground, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      tabBarBackground: Color.lerp(
        tabBarBackground,
        other.tabBarBackground,
        t,
      )!,
      tabUnselected: Color.lerp(tabUnselected, other.tabUnselected, t)!,
      card: Color.lerp(card, other.card, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      chevron: Color.lerp(chevron, other.chevron, t)!,
      bodyText: Color.lerp(bodyText, other.bodyText, t)!,
      nameText: Color.lerp(nameText, other.nameText, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      plainBackground: Color.lerp(plainBackground, other.plainBackground, t)!,
      chatBackground: Color.lerp(chatBackground, other.chatBackground, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      inputExtendBackground: Color.lerp(
        inputExtendBackground,
        other.inputExtendBackground,
        t,
      )!,
      pressed: Color.lerp(pressed, other.pressed, t)!,
    );
  }
}

/// 从上下文读取壳层色板。
extension AppPaletteContext on BuildContext {
  /// 当前壳层色板。
  AppPalette get palette => AppPalette.of(this);

  /// 按当前明暗选择图片资源。
  String themedAsset(String lightAsset, String darkAsset) {
    return palette.brightness == Brightness.dark ? darkAsset : lightAsset;
  }
}
