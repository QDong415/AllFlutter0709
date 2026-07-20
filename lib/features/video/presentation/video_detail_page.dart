import 'package:all_flutter0709/features/video/data/models/video_model.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class VideoDetailPage extends StatelessWidget {
  const VideoDetailPage({required this.video, super.key});

  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '视频详情'),
      backgroundColor: const Color(0xFFF5F5F7),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: video.width > 0 && video.height > 0
                  ? video.width / video.height
                  : 0.72,
              child: video.coverUrl?.isNotEmpty == true
                  ? CachedNetworkImage(
                      imageUrl: video.coverUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: const Color(0xFFEDEDED),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.play_circle_outline_rounded,
                        size: 56,
                        color: Color(0xFF999999),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  video.displayTime,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF777777),
                  ),
                ),
                if (video.content.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    video.content,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(label: '评论 ${video.commentCount}'),
                    _InfoChip(label: '点赞 ${video.likeCount}'),
                    _InfoChip(label: '阅读 ${video.readCount}'),
                    _InfoChip(label: '分享 ${video.shareCount}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
      ),
    );
  }
}
