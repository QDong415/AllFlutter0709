import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';

class ConversationPage extends StatelessWidget {
  const ConversationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '对话 Conversation'),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text('会话 ${index + 1}'),
            subtitle: const Text('这里后续可以接入最近消息、未读数、在线状态。'),
            trailing: const Icon(Icons.chevron_right),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemCount: 12,
      ),
    );
  }
}
