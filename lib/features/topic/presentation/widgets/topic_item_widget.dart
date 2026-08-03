import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/app/theme/app_dimens.dart';
import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_comment_preview_list.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_content_text.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_feed_video_player.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_like_button.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_picture_grid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 动态列表项点击 / 分享 / 点赞等交互回调。
abstract class TopicItemActionListener {
  Future<void> onItemTap(TopicModel topic);

  void onShareTap(TopicModel topic);

  void onAvatarTap(TopicModel topic);

  Future<void> onCommentTap(TopicModel topic);

  void onLikeTap(TopicModel topic);

  void onMentionTap(TopicModel topic, String mention);

  void onHashtagTap(TopicModel topic, String hashtag);

  void onLinkTap(TopicModel topic, String url);

  void onCommentUserTap(
    TopicModel topic,
    TopicCommentModel comment,
    String userId,
    String userName,
    String? avatar,
  );
}

/// 单条动态卡片（头像 / 正文 / 图片或视频 / 评论预览 / 操作栏）。
class TopicItemWidget extends StatelessWidget {
  const TopicItemWidget({
    super.key,
    required this.topicModel,
    this.listener,
    this.playVideo = false,
    this.videoResumeNonce = 0,
  });

  final TopicModel topicModel;
  final TopicItemActionListener? listener;

  /// 列表可视区内时由外部置为 true，触发视频自动播放。
  final bool playVideo;

  /// 从详情返回等场景递增，迫使内嵌视频重新同步播放状态。
  final int videoResumeNonce;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = topicModel.avatar ?? '';
    final content = topicModel.content?.trim() ?? '';
    final videoUrl = topicModel.videoUrl?.trim() ?? '';
    final hasVideo = videoUrl.isNotEmpty;
    final commentCount = topicModel.commentCount > 0
        ? topicModel.commentCount
        : 0;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => listener?.onItemTap(topicModel),
        child: Column(
          children: [
            const Divider(
              height: AppDimens.dividerThickness,
              thickness: AppDimens.dividerThickness,
              color: AppColors.divider,
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => listener?.onAvatarTap(topicModel),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: avatarUrl.isNotEmpty
                          ? CachedNetworkImageProvider(avatarUrl)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topicModel.userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF304F84),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          topicModel.displayTime,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400),
                ],
              ),
            ),
            if (content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TopicContentText(
                    text: content,
                    style: const TextStyle(fontSize: 18),
                    onMentionTap: (mention) =>
                        listener?.onMentionTap(topicModel, mention),
                    onHashtagTap: (hashtag) =>
                        listener?.onHashtagTap(topicModel, hashtag),
                    onLinkTap: (url) => listener?.onLinkTap(topicModel, url),
                  ),
                ),
              ),
            ],
            if (hasVideo) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TopicFeedVideoPlayer(
                  videoUrl: videoUrl,
                  coverPicture: topicModel.pictures.isNotEmpty
                      ? topicModel.pictures.first
                      : null,
                  play: playVideo,
                  resumeNonce: videoResumeNonce,
                ),
              ),
            ] else if (topicModel.pictures.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TopicPictureGrid(pictures: topicModel.pictures),
                ),
              ),
            ],
            if (topicModel.comments.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TopicCommentPreviewList(
                  topic: topicModel,
                  comments: topicModel.comments,
                  onTap: () => listener?.onCommentTap(topicModel),
                  onCommentUserTap:
                      (topic, comment, userId, userName, avatar) =>
                          listener?.onCommentUserTap(
                            topic,
                            comment,
                            userId,
                            userName,
                            avatar,
                          ),
                  onMentionTap: (mention) =>
                      listener?.onMentionTap(topicModel, mention),
                  onHashtagTap: (hashtag) =>
                      listener?.onHashtagTap(topicModel, hashtag),
                  onLinkTap: (url) => listener?.onLinkTap(topicModel, url),
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Divider(
              height: AppDimens.dividerThickness,
              thickness: AppDimens.dividerThickness,
              color: AppColors.divider,
            ),
            SizedBox(
              height: 48,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ActionButton(
                    icon: const Icon(
                      Icons.share_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                    text: '分享',
                    onTap: () => listener?.onShareTap(topicModel),
                  ),
                  _ActionButton(
                    icon: const Icon(
                      Icons.mode_comment_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                    text: commentCount > 0 ? '评论 $commentCount' : '评论',
                    onTap: () => listener?.onCommentTap(topicModel),
                  ),
                  Expanded(
                    child: TopicLikeButton(
                      isLiked: topicModel.isLiked,
                      likeCount: topicModel.likeCount,
                      onTap: () => listener?.onLikeTap(topicModel),
                      mainAxisSize: MainAxisSize.min,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: AppDimens.dividerThickness,
              thickness: AppDimens.dividerThickness,
              color: AppColors.divider,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final Widget icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: const Color(0xFFF5F5F7),
          highlightColor: const Color(0xFFF5F5F7),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 4),
              Text(
                text,
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
