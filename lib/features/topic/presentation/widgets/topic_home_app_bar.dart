import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/app/theme/app_dimens.dart';
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
        width: 210,
        child: TabBar(
          controller: tabController,
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
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(height: 40, text: '最新'),
            Tab(height: 40, text: '关注'),
            Tab(height: 40, text: '匹配'),
          ],
        ),
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
