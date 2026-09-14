import 'package:all_flutter0709/features/conversation/presentation/helpers/chat_panel_helper.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_emoji_panel.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_input_bar.dart';
import 'package:chat_bottom_container/chat_bottom_container.dart';
import 'package:flutter/material.dart';

/// 聊天页底部容器：键盘占位 / 表情 / 拓展面板。
class ChatBottomPanelHost extends StatelessWidget {
  const ChatBottomPanelHost({
    super.key,
    required this.controller,
    required this.inputFocusNode,
    required this.onPanelTypeChange,
    required this.onSendImage,
    required this.onEmojiTap,
  });

  final ChatBottomPanelContainerController<ChatPanelType> controller;
  final FocusNode inputFocusNode;
  final void Function(ChatBottomPanelType panelType, ChatPanelType? data)
  onPanelTypeChange;
  final VoidCallback onSendImage;
  final ValueChanged<String> onEmojiTap;

  @override
  Widget build(BuildContext context) {
    return ChatBottomPanelContainer<ChatPanelType>(
      controller: controller,
      inputFocusNode: inputFocusNode,
      panelBgColor: QInputBarColors.extendBackground,
      onPanelTypeChange: onPanelTypeChange,
      otherPanelWidget: (type) {
        if (type == null) {
          return const SizedBox.shrink();
        }
        final height = controller.keyboardHeight > 0
            ? controller.keyboardHeight
            : 280.0;
        switch (type) {
          case ChatPanelType.emoji:
            return ChatEmojiPanel(height: height, onEmojiTap: onEmojiTap);
          case ChatPanelType.tool:
            return SizedBox(
              width: double.infinity,
              height: height,
              child: ChatFuncPanel(onSendImage: onSendImage),
            );
          case ChatPanelType.none:
          case ChatPanelType.keyboard:
            return const SizedBox.shrink();
        }
      },
    );
  }
}
