import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_content_text.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_like_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

abstract class TopicItemActionListener {
  void onItemTap(TopicModel topic);

  void onShareTap(TopicModel topic);

  void onAvatarTap(TopicModel topic);

  void onCommentTap(TopicModel topic);

  void onLikeTap(TopicModel topic);

  void onMentionTap(TopicModel topic, String mention);

  void onHashtagTap(TopicModel topic, String hashtag);

  void onLinkTap(TopicModel topic, String url);
}

class TopicItemWidget extends StatelessWidget {
  const TopicItemWidget({required this.topicModel, super.key, this.listener});

  final TopicModel topicModel;
  final TopicItemActionListener? listener;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = topicModel.avatar ?? '';
    final content = topicModel.content?.trim() ?? '';
    final commentCount = topicModel.commentCount > 0
        ? topicModel.commentCount
        : 0;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => listener?.onItemTap(topicModel),
        child: Column(
          children: [
            const Divider(height: 0.5),
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
            const SizedBox(height: 8),
            const Divider(height: 0.5),
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
            const Divider(height: 0.5),
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
