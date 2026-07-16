import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';

class TopicDetailPage extends StatelessWidget {
  const TopicDetailPage({
    required this.topic,
    super.key,
  });

  final TopicModel topic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '动态详情'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            topic.userName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            topic.content?.isNotEmpty == true ? topic.content! : '（无正文）',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.mode_comment_outlined),
              const SizedBox(width: 6),
              Text('评论 ${topic.commentCount}'),
              const SizedBox(width: 24),
              const Icon(Icons.thumb_up_alt_outlined),
              const SizedBox(width: 6),
              Text('点赞 ${topic.likeCount}'),
            ],
          ),
          const SizedBox(height: 16),
          Text('tid: ${topic.tid}'),
        ],
      ),
    );
  }
}
