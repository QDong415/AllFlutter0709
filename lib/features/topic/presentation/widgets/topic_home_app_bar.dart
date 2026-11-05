import 'package:all_flutter0709/app/theme/app_dimens.dart';
import 'package:all_flutter0709/features/home/presentation/widgets/home_feed_tab_bar.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_gender_filter_button.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';

/// 动态首页导航栏：左筛选、中 Tab、右发布。
class TopicHomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TopicHomeAppBar({
    super.key,
    required this.tabController,
    required this.gender,
    required this.onGenderChanged,
    required this.onPublishTap,
    this.isPublishBusy = false,
  });

  final TabController tabController;
  final int gender;
  final ValueChanged<int> onGenderChanged;
  final VoidCallback onPublishTap;
  final bool isPublishBusy;

  @override
  Size get preferredSize => const Size.fromHeight(AppDimens.toolbarHeight);

  @override
  Widget build(BuildContext context) {
    return CommonAppBar(
      leadingWidth: 52,
      leading: TopicGenderFilterButton(
        gender: gender,
        onGenderChanged: onGenderChanged,
      ),
      titleWidget: SizedBox(
        width: 280,
        child: HomeFeedTabBar(controller: tabController),
      ),
      actions: [
        IconButton(
          onPressed: isPublishBusy ? null : onPublishTap,
          tooltip: '发布动态',
          icon: const Icon(Icons.photo_camera_outlined),
        ),
      ],
    );
  }
}
