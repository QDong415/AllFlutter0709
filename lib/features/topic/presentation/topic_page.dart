import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/features/topic/presentation/helpers/topic_gender.dart';
import 'package:all_flutter0709/features/topic/presentation/topic_feed_list_page.dart';
import 'package:all_flutter0709/features/topic/presentation/user_match_list_page.dart';
import 'package:all_flutter0709/features/topic/presentation/topic_publish_controller.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_home_app_bar.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_submit_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 动态 Tab 首页：性别筛选 + 最新/关注/匹配 + 发布入口。
class TopicPage extends StatefulWidget {
  const TopicPage({super.key});

  @override
  State<TopicPage> createState() => _TopicPageState();
}

class _TopicPageState extends State<TopicPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _gender = TopicGender.unlimited;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onPublishTap() {
    if (!context.ensureLoggedIn()) {
      return;
    }
    context.push('${AppRoutes.topic}/${AppRoutes.topicSubmit}');
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.providerContainer.read(
      topicPublishControllerProvider,
    );
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: TopicHomeAppBar(
            tabController: _tabController,
            gender: _gender,
            onGenderChanged: (gender) {
              setState(() {
                _gender = gender;
              });
            },
            onPublishTap: _onPublishTap,
            isPublishBusy: controller.isBusy,
          ),
          backgroundColor: AppColors.bodyBackground,
          body: Column(
            children: [
              TopicSubmitProgressBar(controller: controller),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    TopicFeedListPage(
                      gender: _gender,
                      listenPublishSuccess: true,
                    ),
                    TopicFeedListPage(gender: _gender, onlyFollow: true),
                    UserMatchListPage(gender: _gender),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
