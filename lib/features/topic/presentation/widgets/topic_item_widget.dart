import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:flutter/material.dart';

class TopicItemWidget extends StatelessWidget {
  const TopicItemWidget({
    required this.topicModel,
    super.key,
    this.onTap,
  });

  final TopicModel topicModel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = topicModel.avatar ?? '';
    final content = topicModel.content?.trim() ?? '';
    final commentCount = topicModel.commentCount > 0 ? topicModel.commentCount : 0;
    final likeCount = topicModel.likeCount > 0 ? topicModel.likeCount : 0;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            const Divider(height: 0.5),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
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
                          _formatTime(topicModel.createTime),
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
                  child: Text(
                    content,
                    style: const TextStyle(fontSize: 18),
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
                    icon: Icons.share_outlined,
                    text: '分享',
                    onTap: () {},
                  ),
                  _ActionButton(
                    icon: Icons.mode_comment_outlined,
                    text: commentCount > 0 ? '评论 $commentCount' : '评论',
                    onTap: () {},
                  ),
                  _ActionButton(
                    icon: Icons.thumb_up_alt_outlined,
                    text: likeCount > 0 ? '点赞 $likeCount' : '点赞',
                    onTap: () {},
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

  String _formatTime(int timestamp) {
    if (timestamp <= 0) return '--';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
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
              Icon(icon, size: 18, color: Colors.grey),
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
