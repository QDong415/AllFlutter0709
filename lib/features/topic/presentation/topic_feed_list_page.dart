import 'dart:async';

import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/features/topic/presentation/topic_list_base_state.dart';
import 'package:all_flutter0709/features/topic/presentation/topic_publish_controller.dart';
import 'package:flutter/material.dart';

/// 动态首页「最新 / 关注」列表，对齐 Android `TopicFragment`。
class TopicFeedListPage extends StatefulWidget {
  const TopicFeedListPage({
    super.key,
    required this.gender,
    this.onlyFollow = false,
    this.listenPublishSuccess = false,
  });

  /// 性别筛选：0 不限 / 1 男 / 2 女。
  final int gender;

  /// 是否只看关注的人。
  final bool onlyFollow;

  /// 发布成功后是否刷新（仅「最新」Tab）。
  final bool listenPublishSuccess;

  @override
  State<TopicFeedListPage> createState() => _TopicFeedListPageState();
}

class _TopicFeedListPageState extends TopicListBaseState<TopicFeedListPage>
    with AutomaticKeepAliveClientMixin {
  TopicPublishController? _publishController;

  @override
  bool get wantKeepAlive => true;

  @override
  bool get useDefaultScaffold => false;

  @override
  String get emptyText => widget.onlyFollow ? '还没有关注的人发动态' : '暂无动态';

  @override
  Map<String, dynamic>? customParameters() {
    return <String, dynamic>{
      if (widget.onlyFollow) 'onlyfollow': '1',
      if (widget.gender != 0) 'gender': widget.gender,
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.listenPublishSuccess) {
      return;
    }
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
  void didUpdateWidget(covariant TopicFeedListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gender != widget.gender ||
        oldWidget.onlyFollow != widget.onlyFollow) {
      unawaited(onRefreshList());
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return buildTopicListBody();
  }
}
