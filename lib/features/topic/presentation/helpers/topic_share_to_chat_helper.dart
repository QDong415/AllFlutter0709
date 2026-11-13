import 'dart:async';

import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/features/conversation/presentation/conversation_controller.dart';
import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:all_flutter0709/features/topic/data/topic_repository.dart';
import 'package:all_flutter0709/features/user/data/models/user_base_model.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 把动态私信分享给选中好友：选人 → 发 subtype=topic 消息 → toast。
///
/// 列表 / 详情等入口统一走这里；选人逻辑复用 [TopicUserSelectPage]。
class TopicShareToChatHelper {
  const TopicShareToChatHelper({
    TopicRepository topicRepository = const TopicRepository(),
  }) : _topicRepository = topicRepository;

  final TopicRepository _topicRepository;

  /// 弹出选人并分享 [topicModel]；取消选人不提示。
  Future<void> share({
    required BuildContext context,
    required TopicModel topicModel,
  }) async {
    if (!context.ensureLoggedIn()) {
      return;
    }
    if (topicModel.tid.isEmpty) {
      AppToast.show(context, '动态无效');
      return;
    }

    final userModel = await context.push<UserBaseModel>(
      '${AppRoutes.topic}/${AppRoutes.topicUserSelect}',
    );
    if (!context.mounted || userModel == null) {
      return;
    }
    if (userModel.userId.isEmpty) {
      AppToast.show(context, '请选择好友');
      return;
    }

    final coverPicture = topicModel.pictures.isNotEmpty
        ? topicModel.pictures.first.originalUrl
        : '';

    try {
      final controller = context.providerContainer.read(
        conversationControllerProvider,
      );
      await controller.sendTopicMessage(
        conversationId: userModel.userId,
        tid: topicModel.tid,
        topicContent: topicModel.content?.trim() ?? '',
        picture: coverPicture,
        authorUserId: topicModel.userId,
        authorName: topicModel.userName,
        authorAvatar: topicModel.avatar ?? '',
        hasVideo: topicModel.hasVideo,
        peerName: userModel.name,
        peerAvatar: userModel.avatar ?? '',
        peerUserType: userModel.userType,
        peerGender: userModel.gender,
      );
      if (!context.mounted) {
        return;
      }
      AppToast.show(context, '已分享');
      unawaited(_topicRepository.reportShare(tid: topicModel.tid));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      final text = error.toString().replaceFirst('Exception: ', '');
      AppToast.show(context, text.isEmpty ? '分享失败' : text);
    }
  }
}
