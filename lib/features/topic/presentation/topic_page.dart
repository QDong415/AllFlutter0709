import 'dart:async';

import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/core/vip/vip_topic_guard.dart';
import 'package:all_flutter0709/features/conversation/presentation/helpers/vip_chat_guard.dart';
import 'package:all_flutter0709/features/ai/presentation/ai_character_page.dart';
import 'package:all_flutter0709/features/topic/presentation/helpers/topic_gender.dart';
import 'package:all_flutter0709/features/topic/presentation/topic_feed_list_page.dart';
import 'package:all_flutter0709/features/topic/presentation/user_match_list_page.dart';
import 'package:all_flutter0709/features/topic/presentation/topic_publish_controller.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_home_app_bar.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_submit_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 动态 Tab 首页：性别筛选 + 最新/关注/匹配/AI + 发布入口。
///
/// 四个子页共用同一顶栏，可横滑切换；离开 feed 列表 Tab 时暂停视频 ticker。
class TopicPage extends StatefulWidget {
  const TopicPage({super.key, this.initialFeedTab});

  /// 例如 `/topic?feedTab=ai` 或旧链 `/ai` 重定向。
  final String? initialFeedTab;

  @override
  State<TopicPage> createState() => _TopicPageState();
}

class _TopicPageState extends State<TopicPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _gender = TopicGender.unlimited;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    if (widget.initialFeedTab == 'ai') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _tabController.index = 3;
        setState(() => _tabIndex = 3);
      });
    }
  }

  void _onTabChanged() {
    if (_tabController.index == _tabIndex) {
      return;
    }
    setState(() => _tabIndex = _tabController.index);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onPublishTap() async {
    if (!context.ensureLoggedIn()) {
      return;
    }
    final account = context.providerContainer.read(accountProvider);
    if (account != null && topicPublishRequiresVip(account: account)) {
      await showVipRequiredDialog(context);
      return;
    }
    if (!mounted) {
      return;
    }
    context.push('${AppRoutes.topic}/${AppRoutes.topicSubmit}');
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.providerContainer.read(
      topicPublishControllerProvider,
    );
    final feedTickerEnabled = _tabIndex < 3;
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
            onPublishTap: () => unawaited(_onPublishTap()),
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
                    TickerMode(
                      enabled: feedTickerEnabled && _tabIndex == 0,
                      child: TopicFeedListPage(
                        gender: _gender,
                        listenPublishSuccess: true,
                      ),
                    ),
                    TickerMode(
                      enabled: feedTickerEnabled && _tabIndex == 1,
                      child: TopicFeedListPage(
                        gender: _gender,
                        onlyFollow: true,
                      ),
                    ),
                    TickerMode(
                      enabled: feedTickerEnabled && _tabIndex == 2,
                      child: UserMatchListPage(gender: _gender),
                    ),
                    const AiCharacterPage(),
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
