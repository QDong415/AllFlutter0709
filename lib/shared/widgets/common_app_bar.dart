import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/app/theme/app_dimens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 通用导航栏：高度 / 色值对齐 QKotlin Toolbar，标题居中。
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({
    required this.title,
    super.key,
    this.actions,
  });

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(AppDimens.toolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: AppDimens.toolbarHeight,
      centerTitle: true,
      backgroundColor: AppColors.toolbar,
      foregroundColor: AppColors.titleText,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.tabBarBackground,
        systemNavigationBarDividerColor: AppColors.tabBarBackground,
        systemNavigationBarContrastEnforced: false,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.titleText,
          fontSize: AppDimens.toolbarTitleSize,
          fontWeight: FontWeight.w400,
        ),
      ),
      actions: actions,
    );
  }
}
