import 'dart:async';

import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/features/gift/presentation/gift_send_animation.dart';
import 'package:all_flutter0709/features/gift/presentation/gift_sheet.dart';
import 'package:all_flutter0709/features/gift/presentation/topic_received_gift_strip.dart';
import 'package:all_flutter0709/features/common/widget/round_icon_label_chip.dart';
import 'package:all_flutter0709/features/comment/data/comment_repository.dart';
import 'package:all_flutter0709/features/comment/presentation/widgets/comment_section.dart';
import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:all_flutter0709/features/topic/data/topic_repository.dart';
import 'package:all_flutter0709/features/topic/presentation/helpers/topic_delete_helper.dart';
import 'package:all_flutter0709/features/topic/presentation/helpers/topic_like_helper.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_content_text.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_feed_video_player.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_like_button.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_more_button.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_picture_grid.dart';
import 'package:all_flutter0709/features/user/presentation/helpers/user_detail_navigation.dart';
import 'package:all_flutter0709/features/user/presentation/warning_report_page.dart';
import 'package:all_flutter0709/features/user/presentation/widgets/user_ai_tag.dart';
import 'package:all_flutter0709/features/user/presentation/widgets/vip_halo_avatar.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';

class TopicDetailPage extends ConsumerStatefulWidget {
  const TopicDetailPage({super.key, this.tid, this.topicModel})
    : assert(tid != null || topicModel != null, 'tid 和 topicModel 不能同时为空');

  final String? tid;
  final TopicModel? topicModel;

  @override
  ConsumerState<TopicDetailPage> createState() => _TopicDetailPageState();
}

class _TopicDetailPageState extends ConsumerState<TopicDetailPage> {
  final TopicRepository _topicRepository = const TopicRepository();

  TopicModel? _topicModel;
  bool _isLoading = true;
  bool _isLiking = false;
  String? _errorText;
  final GlobalKey<TopicReceivedGiftStripState> _giftStripKey =
      GlobalKey<TopicReceivedGiftStripState>();
  StreamSubscription<Tid>? _deletedTidSubscription;
  StreamSubscription<TopicLikeEvent>? _topicLikeSubscription;

  String get _resolvedTid =>
      (widget.topicModel?.tid ?? widget.tid ?? '').trim();

  @override
  void initState() {
    super.initState();
    _deletedTidSubscription = TopicDeleteHelper.controller.stream.listen(
      _onTopicDeleted,
    );
    _topicLikeSubscription = TopicLikeHelper.controller.stream.listen(
      _onTopicLiked,
    );
    _topicModel = widget.topicModel;
    if (_topicModel == null) {
      _isLoading = true;
      _errorText = null;
      unawaited(_fetchDetail(showLoading: false)); //加不加unawaited都一样，只是个标识
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _deletedTidSubscription?.cancel();
    _topicLikeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchDetail({required bool showLoading}) async {
    if (_resolvedTid.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = '缺少动态id';
      });
      return;
    }

    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorText = null;
      });
    }

    try {
      final topic = await _topicRepository.getTopicDetail(tid: _resolvedTid);
      if (!mounted) return;
      setState(() {
        _topicModel = topic;
        _isLoading = false;
        _errorText = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _sendGift(TopicModel topicModel) async {
    if (!context.ensureLoggedIn()) {
      return;
    }
    final toUserId = topicModel.userId.trim();
    final feedId = topicModel.tid.trim();
    if (toUserId.isEmpty || feedId.isEmpty) {
      AppToast.show(context, '暂时不能给这条动态送礼');
      return;
    }
    final selfId = ref.read(accountProvider)?.userId;
    if (selfId != null && selfId == toUserId) {
      AppToast.show(context, '不能给自己送礼');
      return;
    }
    await showGiftSheet(
      context,
      toUserId: toUserId,
      type: 1,
      feedId: feedId,
      onCombo: (giftModel, count) {
        if (!mounted) {
          return;
        }
        unawaited(
          playGiftSendAnimation(
            context,
            pictureUrl: giftModel.pictureUrl,
            count: count,
          ),
        );
      },
      onSent: (result) {
        _giftStripKey.currentState?.onGiftSent(result);
      },
    );
  }

  Future<void> _toggleLike() async {
    final topicModel = _topicModel;
    if (topicModel == null || _isLiking) return;
    if (!context.ensureLoggedIn()) return;

    _isLiking = true;
    try {
      await TopicLikeHelper.toggle(
        tid: topicModel.tid,
        isLiked: topicModel.isLiked,
        likeCount: topicModel.likeCount,
      );
    } catch (error) {
      if (!mounted) return;
      AppToast.show(context, error.toString().replaceFirst('Exception: ', ''));
    } finally {
      _isLiking = false;
    }
  }

  Future<void> _deleteTopic() async {
    final topicModel = _topicModel;
    if (topicModel == null) {
      return;
    }
    if (!context.ensureLoggedIn()) {
      return;
    }

    try {
      await TopicDeleteHelper.delete(context, topicModel.tid);
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppToast.show(context, error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _onTopicLiked(TopicLikeEvent event) {
    if (!mounted) {
      return;
    }
    final topicModel = _topicModel;
    if (topicModel == null || topicModel.tid != event.tid) {
      return;
    }
    if (topicModel.isLiked == event.isLiked &&
        topicModel.likeCount == event.likeCount) {
      return;
    }
    setState(() {
      _topicModel = topicModel.copyWith(
        isLiked: event.isLiked,
        likeCount: event.likeCount,
      );
    });
  }

  void _onTopicDeleted(Tid tid) {
    if (!mounted) {
      return;
    }
    final currentTid = (_topicModel?.tid ?? _resolvedTid).trim();
    if (currentTid.isEmpty || currentTid != tid) {
      return;
    }
    context.pop();
  }

  void _reportTopic() {
    final topicModel = _topicModel;
    if (topicModel == null) {
      return;
    }
    if (!context.ensureLoggedIn()) {
      return;
    }
    openWarningReportPage(context, toUserId: topicModel.userId);
  }

  @override
  Widget build(BuildContext context) {
    final topicModel = _topicModel;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: const CommonAppBar(title: '动态详情'),
      backgroundColor: AppColors.bodyBackground,
      body: _buildBody(topicModel),
    );
  }

  Widget _buildBody(TopicModel? topicModel) {
    if (topicModel == null && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (topicModel == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_outlined,
                size: 52,
                color: Color(0xFFB3B3B8),
              ),
              const SizedBox(height: 12),
              Text(
                _errorText ?? '动态详情加载失败',
                style: const TextStyle(fontSize: 14, color: Color(0xFF7B7B80)),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  unawaited(_fetchDetail(showLoading: true));
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    } else {
      //已经有 topicModel了
      return CommentSection(
        targetId: topicModel.tid,
        targetType: CommentTargetType.topic,
        initialCommentCount: topicModel.commentCount,
        authorUserId: topicModel.userId,
        onCommentCountChanged: (count) {
          if (!mounted) return;
          setState(() {
            _topicModel = topicModel.copyWith(commentCount: count);
          });
        },
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopicDetailHeader(
              topic: topicModel,
              isLoadingDetail: _isLoading,
              onLikeTap: _toggleLike,
              onGiftTap: () {
                unawaited(_sendGift(topicModel));
              },
              onDeleteTap: _deleteTopic,
              onReportTap: _reportTopic,
              onRefreshTap: _errorText == null
                  ? null
                  : () {
                      unawaited(_fetchDetail(showLoading: false));
                    },
            ),
            TopicReceivedGiftStrip(key: _giftStripKey, feedId: topicModel.tid),
          ],
        ),
      );
    }
  }
}

class _TopicDetailHeader extends StatelessWidget {
  const _TopicDetailHeader({
    required this.topic,
    required this.isLoadingDetail,
    required this.onLikeTap,
    required this.onGiftTap,
    this.onDeleteTap,
    this.onReportTap,
    this.onRefreshTap,
  });

  final TopicModel topic;
  final bool isLoadingDetail;
  final Future<void> Function() onLikeTap;
  final VoidCallback onGiftTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onReportTap;
  final VoidCallback? onRefreshTap;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = topic.avatar ?? '';
    final content = topic.content?.trim() ?? '';
    final videoUrl = topic.videoUrl?.trim() ?? '';
    const avatarSize = 44.0;
    final avatarTop = VipHaloAvatar.avatarOrigin(
      size: avatarSize,
      vip: topic.vip,
    ).dy;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  openUserDetailPage(
                    context,
                    userId: topic.userId,
                    name: topic.userName,
                    avatar: topic.avatar,
                    userType: topic.userType,
                  );
                },
                child: VipHaloAvatar(
                  size: avatarSize,
                  vip: topic.vip,
                  gender: topic.gender,
                  imageUrl: avatarUrl,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: avatarTop),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          openUserDetailPage(
                            context,
                            userId: topic.userId,
                            name: topic.userName,
                            avatar: topic.avatar,
                            userType: topic.userType,
                          );
                        },
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                topic.userName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF304F84),
                                ),
                              ),
                            ),
                            if (topic.isAi) ...[
                              const SizedBox(width: 6),
                              const UserAiTag(compact: true),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        topic.displayTime,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8B8B90),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (onRefreshTap != null)
                Padding(
                  padding: EdgeInsets.only(top: avatarTop),
                  child: IconButton(
                    onPressed: onRefreshTap,
                    icon: const Icon(Icons.refresh_rounded),
                    color: const Color(0xFF8B8B90),
                    tooltip: '刷新详情',
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(top: avatarTop),
                child: TopicMoreButton(
                  topicModel: topic,
                  onDeleteTap: onDeleteTap,
                  onReportTap: onReportTap,
                ),
              ),
            ],
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 14),
            TopicContentText(
              text: content,
              style: const TextStyle(
                fontSize: 17,
                height: 1.6,
                color: Color(0xFF222222),
              ),
              highlightStyle: const TextStyle(
                fontSize: 17,
                height: 1.6,
                color: Color(0xFF2F7CF6),
                fontWeight: FontWeight.w500,
              ),
              onMentionTap: (mention) =>
                  openUserDetailByName(context, name: mention),
            ),
          ],
          if (videoUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            TopicFeedVideoPlayer(
              videoUrl: videoUrl,
              coverPicture: topic.pictures.isNotEmpty
                  ? topic.pictures.first
                  : null,
              play: true,
            ),
          ] else if (topic.pictures.isNotEmpty) ...[
            const SizedBox(height: 12),
            TopicPictureGrid(pictures: topic.pictures),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              RoundIconLabelChip(
                icon: Icons.mode_comment_outlined,
                label: topic.commentCount > 0
                    ? '评论 ${topic.commentCount}'
                    : '评论',
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onGiftTap,
                child: const RoundIconLabelChip(
                  icon: Icons.card_giftcard,
                  label: '送礼',
                ),
              ),
              const SizedBox(width: 10),
              RoundIconLabelChip(
                icon: Icons.tag_rounded,
                label: 'tid ${topic.tid}',
              ),
              const Spacer(),
              Opacity(
                opacity: isLoadingDetail ? 0.7 : 1,
                child: TopicLikeButton(
                  isLiked: topic.isLiked,
                  likeCount: topic.likeCount,
                  fontSize: 14,
                  iconSize: 18,
                  onTap: onLikeTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
