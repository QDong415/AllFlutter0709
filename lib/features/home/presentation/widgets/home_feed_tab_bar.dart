import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// 首页顶部：最新、关注、匹配、AI（样式与原先三 Tab 一致，仅多一项）。
class HomeFeedTabBar extends StatelessWidget {
  const HomeFeedTabBar({super.key, required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      labelColor: AppColors.link,
      unselectedLabelColor: AppColors.titleText,
      indicatorColor: AppColors.link,
      indicatorSize: TabBarIndicatorSize.label,
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(width: 4, color: AppColors.link),
      ),
      tabAlignment: TabAlignment.fill,
      dividerColor: Colors.transparent,
      dividerHeight: 0,
      labelPadding: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      unselectedLabelStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      tabs: const [
        Tab(height: 40, text: '最新'),
        Tab(height: 40, text: '关注'),
        Tab(height: 40, text: '匹配'),
        Tab(height: 40, text: 'AI'),
      ],
    );
  }
}
