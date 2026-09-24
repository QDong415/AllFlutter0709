import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/app/theme/app_dimens.dart';
import 'package:all_flutter0709/app/theme/app_shadows.dart';
import 'package:all_flutter0709/app/theme/app_system_ui.dart';
import 'package:flutter/material.dart';

/// 通用导航栏，标题居中。
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({
    super.key,
    this.title = '',
    this.titleWidget,
    this.titleTrailing,
    this.leading,
    this.leadingWidth,
    this.actions,
    this.onLeadingPressed,
  });

  /// 导航栏标题。
  final String title;

  /// 自定义标题（优先于 [title]），例如首页 Tab。
  final Widget? titleWidget;

  /// 标题右侧附加内容，例如 AI 标签。
  final Widget? titleTrailing;

  /// 自定义左侧按钮；设置后不再显示返回。
  final Widget? leading;

  /// 左侧按钮宽度。
  final double? leadingWidth;
  final List<Widget>? actions;

  /// 导航栏返回；为 null 时走系统默认 `maybePop`。
  final VoidCallback? onLeadingPressed;

  @override
  Size get preferredSize => const Size.fromHeight(AppDimens.toolbarHeight);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.toolbar,
        boxShadow: AppShadows.downward,
      ),
      child: AppBar(
        toolbarHeight: AppDimens.toolbarHeight,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.titleText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        clipBehavior: Clip.none,
        automaticallyImplyLeading: leading == null && onLeadingPressed == null,
        leadingWidth: leadingWidth,
        leading:
            leading ??
            (onLeadingPressed == null
                ? null
                : IconButton(
                    icon: const BackButtonIcon(),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: onLeadingPressed,
                  )),
        systemOverlayStyle: AppSystemUi.overlayStyle,
        title:
            titleWidget ??
            (titleTrailing == null
                ? Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.titleText,
                      fontSize: AppDimens.toolbarTitleSize,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.titleText,
                            fontSize: AppDimens.toolbarTitleSize,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      titleTrailing!,
                    ],
                  )),
        actions: actions,
      ),
    );
  }
}
