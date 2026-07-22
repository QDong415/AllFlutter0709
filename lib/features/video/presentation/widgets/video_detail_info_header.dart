import 'package:all_flutter0709/features/video/data/models/video_model.dart';
import 'package:flutter/material.dart';

class VideoDetailInfoHeader extends StatelessWidget {
  const VideoDetailInfoHeader({required this.video, super.key});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    final content = video.content.trim();

    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  video.displayDate,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF8B8B90)),
                ),
                const Spacer(),
                Text(
                  '${video.readCount}次播放',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF8B8B90)),
                ),
              ],
            ),
            if (content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${video.userName}：',
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF304F84),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: content,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            _StatLine(
              icon: Icons.favorite_border_rounded,
              text: '${video.likeCount} 个赞',
            ),
            const SizedBox(height: 8),
            _StatLine(
              icon: Icons.mode_comment_outlined,
              text: '${video.commentCount} 条评论',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF555555)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 14, color: Color(0xFF222222)),
        ),
      ],
    );
  }
}
