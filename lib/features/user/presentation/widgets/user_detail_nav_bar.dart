import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/app/theme/app_dimens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 个人主页双层导航：透明层与实色层按滚动比例渐变。
class UserDetailNavBar extends StatelessWidget {
  const UserDetailNavBar({
    super.key,
    required this.progress,
    required this.title,
    required this.onBack,
    required this.onMore,
  });

  /// 0 = 展开透明，1 = 完全收起实色。
  final double progress;
  final String title;
  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final barHeight = statusBarHeight + AppDimens.toolbarHeight;
    final solidOpacity = progress.clamp(0.0, 1.0);
    final clearOpacity = (1.0 - solidOpacity).clamp(0.0, 1.0);

    // 只切换状态栏图标明暗，不要用 SystemUiOverlayStyle.light/dark：
    // 它们会把 systemNavigationBarColor 设成黑色，小米等机型底部指示器区域会变黑。
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: solidOpacity > 0.5
          ? Brightness.dark
          : Brightness.light,
      statusBarBrightness: solidOpacity > 0.5
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarColor: AppColors.tabBarBackground,
      systemNavigationBarDividerColor: AppColors.tabBarBackground,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarIconBrightness: Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: SizedBox(
        height: barHeight,
        child: Stack(
          children: [
            Opacity(
              opacity: clearOpacity,
              child: _NavBarContent(
                statusBarHeight: statusBarHeight,
                backgroundColor: Colors.transparent,
                title: '',
                titleColor: Colors.white,
                iconColor: Colors.white,
                onBack: onBack,
                onMore: onMore,
                useShadowIcon: true,
              ),
            ),
            Opacity(
              opacity: solidOpacity,
              child: _NavBarContent(
                statusBarHeight: statusBarHeight,
                backgroundColor: AppColors.toolbar,
                title: title,
                titleColor: AppColors.titleText,
                iconColor: AppColors.titleText,
                onBack: onBack,
                onMore: onMore,
                useShadowIcon: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarContent extends StatelessWidget {
  const _NavBarContent({
    required this.statusBarHeight,
    required this.backgroundColor,
    required this.title,
    required this.titleColor,
    required this.iconColor,
    required this.onBack,
    required this.onMore,
    required this.useShadowIcon,
  });

  final double statusBarHeight;
  final Color backgroundColor;
  final String title;
  final Color titleColor;
  final Color iconColor;
  final VoidCallback onBack;
  final VoidCallback onMore;
  final bool useShadowIcon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: Padding(
        padding: EdgeInsets.only(top: statusBarHeight),
        child: SizedBox(
          height: AppDimens.toolbarHeight,
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: iconColor,
                  shadows: useShadowIcon
                      ? const [
                          Shadow(
                            color: Color(0x66000000),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppDimens.toolbarTitleSize,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: onMore,
                icon: Icon(
                  Icons.more_horiz_rounded,
                  size: 24,
                  color: iconColor,
                  shadows: useShadowIcon
                      ? const [
                          Shadow(
                            color: Color(0x66000000),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
