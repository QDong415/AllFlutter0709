import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';

class TopicDetailPage extends StatelessWidget {
  const TopicDetailPage({
    required this.tid,
    super.key,
    this.topic,
  });

  final String tid;
  final TopicModel? topic;

  TopicModel get _displayTopic {
    return topic ??
        TopicModel(
          tid: tid,
          userName: '未知用户',
          isLiked: false,
          likeCount: 0,
          commentCount: 0,
          createTime: 0,
          displayTime: '--',
          content: null,
          avatar: null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final data = _displayTopic;
    return Scaffold(
      appBar: const CommonAppBar(title: '动态详情'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            data.userName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            data.content?.isNotEmpty == true ? data.content! : '（无正文）',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.mode_comment_outlined),
              const SizedBox(width: 6),
              Text('评论 ${data.commentCount}'),
              const SizedBox(width: 24),
              const Icon(Icons.thumb_up_alt_outlined),
              const SizedBox(width: 6),
              Text('点赞 ${data.likeCount}'),
            ],
          ),
          const SizedBox(height: 16),
          Text('tid: ${data.tid}'),
        ],
      ),
    );
  }
}
