import 'dart:async';

import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/features/common/widget/round_icon_label_chip.dart';
import 'package:all_flutter0709/features/comment/data/comment_repository.dart';
import 'package:all_flutter0709/features/comment/presentation/widgets/comment_section.dart';
import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:all_flutter0709/features/topic/data/topic_repository.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_content_text.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_like_button.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_picture_grid.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TopicDetailPage extends ConsumerStatefulWidget {
  const TopicDetailPage({
    super.key,
    this.tid,
    this.topicModel,
  }) : assert(tid != null || topicModel != null, 'tid 和 topicModel 不能同时为空');

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

  String get _resolvedTid => (widget.topicModel?.tid ?? widget.tid ?? '').trim();

  @override
  void initState() {
    super.initState();
    _topicModel = widget.topicModel;
    if (_topicModel == null) {
      _isLoading = true;
      _errorText = null;
      unawaited(_fetchDetail(showLoading: false)); //加不加unawaited都一样，只是个标识
    } else {
      _isLoading = false;
    }
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

  Future<void> _toggleLike() async {
    final topicModel = _topicModel;
    if (topicModel == null || _isLiking) return;
    if (!context.ensureLoggedIn()) return;

    final nextIsLiked = !topicModel.isLiked;
    final nextLikeCount = nextIsLiked
        ? topicModel.likeCount + 1
        : (topicModel.likeCount > 0 ? topicModel.likeCount - 1 : 0);
    final optimisticTopic = topicModel.copyWith(
      isLiked: nextIsLiked,
      likeCount: nextLikeCount,
    );

    setState(() {
      _topicModel = optimisticTopic;
      _isLiking = true;
    });

    try {
      await _topicRepository.likeTopic(
        tid: topicModel.tid,
        isLiked: topicModel.isLiked,
        likeCount: topicModel.likeCount,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _topicModel = topicModel;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLiking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topicModel = _topicModel;
    return Scaffold(
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
        header: _TopicDetailHeader(
          topic: topicModel,
          isLoadingDetail: _isLoading,
          onLikeTap: _toggleLike,
          onRefreshTap: _errorText == null
              ? null
              : () {
            unawaited(_fetchDetail(showLoading: false));
          },
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
    this.onRefreshTap,
  });

  final TopicModel topic;
  final bool isLoadingDetail;
  final Future<void> Function() onLikeTap;
  final VoidCallback? onRefreshTap;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = topic.avatar ?? '';
    final content = topic.content?.trim() ?? '';

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
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE8E8E8),
                backgroundImage: avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF304F84),
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
              if (onRefreshTap != null)
                IconButton(
                  onPressed: onRefreshTap,
                  icon: const Icon(Icons.refresh_rounded),
                  color: const Color(0xFF8B8B90),
                  tooltip: '刷新详情',
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
            ),
          ],
          if (topic.pictures.isNotEmpty) ...[
            const SizedBox(height: 12),
            TopicPictureGrid(pictures: topic.pictures),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              RoundIconLabelChip(
                icon: Icons.mode_comment_outlined,
                label: topic.commentCount > 0 ? '评论 ${topic.commentCount}' : '评论',
              ),
              const SizedBox(width: 10),
              RoundIconLabelChip(icon: Icons.tag_rounded, label: 'tid ${topic.tid}'),
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
