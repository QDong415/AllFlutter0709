import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/app/theme/app_dimens.dart';
import 'package:all_flutter0709/app/theme/app_shadows.dart';
import 'package:all_flutter0709/app/theme/app_system_ui.dart';
import 'package:flutter/material.dart';

/// 通用导航栏，标题居中。
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
        systemOverlayStyle: AppSystemUi.overlayStyle,
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.titleText,
            fontSize: AppDimens.toolbarTitleSize,
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: actions,
      ),
    );
  }
}
