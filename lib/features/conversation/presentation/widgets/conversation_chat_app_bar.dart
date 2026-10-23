import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';
import 'package:all_flutter0709/features/conversation/presentation/helpers/chat_ai_typing_helper.dart';
import 'package:all_flutter0709/features/user/presentation/widgets/user_ai_tag.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 聊天页导航栏，只监听当前会话消息以展示 AI 输入状态。
class ConversationChatAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const ConversationChatAppBar({
    super.key,
    required this.messagesListenable,
    required this.conversationName,
    required this.peerIsAi,
    required this.aiTypingHelper,
    required this.onLeadingPressed,
    required this.onPeerPressed,
  });

  final ValueListenable<AsyncValue<List<ConversationMessage>>>
  messagesListenable;
  final String conversationName;
  final bool peerIsAi;
  final ChatAiTypingHelper aiTypingHelper;
  final VoidCallback onLeadingPressed;

  /// 打开对方个人主页。
  final VoidCallback onPeerPressed;

  @override
  Size get preferredSize => const CommonAppBar().preferredSize;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AsyncValue<List<ConversationMessage>>>(
      valueListenable: messagesListenable,
      builder: (context, state, _) {
        final messageList = state is AsyncData<List<ConversationMessage>>
            ? state.value
            : const <ConversationMessage>[];
        final incomingCount = messageList
            .where((message) => !message.isSender)
            .length;
        final isPeerTyping = peerIsAi && aiTypingHelper.isTyping(incomingCount);
        return CommonAppBar(
          title: isPeerTyping ? '对方正在输入中...' : conversationName,
          titleTrailing: peerIsAi && !isPeerTyping ? const UserAiTag() : null,
          actions: [
            IconButton(
              tooltip: '个人主页',
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 45),
              onPressed: onPeerPressed,
              icon: const Icon(
                Icons.person_outline,
                size: 22,
                color: AppColors.titleText,
              ),
            ),
          ],
          onLeadingPressed: onLeadingPressed,
        );
      },
    );
  }
}
