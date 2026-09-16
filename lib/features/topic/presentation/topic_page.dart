import 'dart:async';

import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/features/topic/presentation/topic_list_base_state.dart';
import 'package:all_flutter0709/features/topic/presentation/topic_publish_controller.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_submit_progress_bar.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 动态 Tab 首页：列表 + 发布入口 + 上传进度条。
class TopicPage extends StatefulWidget {
  const TopicPage({super.key});

  @override
  State<TopicPage> createState() => _TopicPageState();
}

class _TopicPageState extends TopicListBaseState<TopicPage> {
  TopicPublishController? _publishController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.providerContainer.read(
      topicPublishControllerProvider,
    );
    if (!identical(_publishController, controller)) {
      _publishController?.removeListener(_onPublishChanged);
      _publishController = controller;
      _publishController!.addListener(_onPublishChanged);
    }
  }

  @override
  void dispose() {
    _publishController?.removeListener(_onPublishChanged);
    super.dispose();
  }

  void _onPublishChanged() {
    final controller = _publishController;
    if (controller == null || !mounted) {
      return;
    }
    if (controller.shouldRefreshList) {
      controller.markListRefreshed();
      unawaited(onRefreshList());
    }
  }

  void _onPublishTap() {
    if (!context.ensureLoggedIn()) {
      return;
    }
    context.push('${AppRoutes.topic}/${AppRoutes.topicSubmit}');
  }

  @override
  PreferredSizeWidget? buildAppBar() {
    final controller = context.providerContainer.read(
      topicPublishControllerProvider,
    );
    return CommonAppBar(
      title: pageTitle,
      actions: [
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return IconButton(
              onPressed: controller.isBusy ? null : _onPublishTap,
              tooltip: '发布动态',
              icon: const Icon(Icons.photo_camera_outlined),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.providerContainer.read(
      topicPublishControllerProvider,
    );
    return Scaffold(
      appBar: buildAppBar(),
      backgroundColor: AppColors.bodyBackground,
      body: Column(
        children: [
          TopicSubmitProgressBar(controller: controller),
          Expanded(child: buildTopicListBody()),
        ],
      ),
    );
  }
}
