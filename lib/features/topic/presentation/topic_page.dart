import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';

class TopicPage extends StatelessWidget {
  const TopicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '动态 Topic'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _TopicCard(
            title: '推荐动态流',
            subtitle: '后续可以接入推荐 feed、关注 feed、发布入口和详情页。',
          ),
          SizedBox(height: 12),
          _TopicCard(
            title: '内容模块占位',
            subtitle: '建议继续拆成列表项、卡片组件、发布组件、评论入口。',
          ),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.topic_outlined),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
