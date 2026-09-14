import 'package:chat_bottom_container/chat_bottom_container.dart';
import 'package:flutter/material.dart';

/// 底部容器面板：无 / 键盘 / 表情 / 拓展。
enum ChatPanelType { none, keyboard, emoji, tool }

/// 对接 `ChatBottomPanelContainer` 的面板切换与输入框 readOnly。
class ChatPanelHelper {
  ChatPanelHelper({required this.inputFocusNode, required this.onUpdate});

  /// 输入框焦点，交给底部容器监听。
  final FocusNode inputFocusNode;

  /// 只读态 / 面板类型变化时刷新界面。
  final VoidCallback onUpdate;

  /// 底部容器控制器。
  final ChatBottomPanelContainerController<ChatPanelType> controller =
      ChatBottomPanelContainerController<ChatPanelType>();

  /// 当前对外面板类型（含自定义 emoji / tool）。
  ChatPanelType currentPanelType = ChatPanelType.none;

  /// 表情面板时为 true，避免弹出系统键盘但保留光标。
  bool readOnly = false;

  /// 软键盘或自定义面板是否正在显示。
  bool get isPanelOrKeyboardVisible {
    return inputFocusNode.hasFocus ||
        controller.currentPanelType != ChatBottomPanelType.none;
  }

  /// 收起键盘与自定义面板。
  void hidePanel() {
    if (inputFocusNode.hasFocus) {
      inputFocusNode.unfocus();
    }
    updateInputView(isReadOnly: false);
    if (controller.currentPanelType == ChatBottomPanelType.none) {
      return;
    }
    controller.updatePanelType(ChatBottomPanelType.none);
  }

  /// 切换到指定面板。
  ///
  /// 表情面板下输入框是 `readOnly + 仍有焦点`。切到拓展面板时不能先取消只读，
  /// 否则系统键盘会抢先弹一下再被收掉。
  void updatePanelType(ChatPanelType type) {
    final isSwitchToKeyboard = type == ChatPanelType.keyboard;
    final isSwitchToEmojiPanel = type == ChatPanelType.emoji;
    var isUpdated = false;
    switch (type) {
      case ChatPanelType.keyboard:
        updateInputView(isReadOnly: false);
      case ChatPanelType.emoji:
        isUpdated = updateInputView(isReadOnly: true);
      case ChatPanelType.tool:
      case ChatPanelType.none:
        break;
    }

    void applyPanelType() {
      controller.updatePanelType(
        isSwitchToKeyboard
            ? ChatBottomPanelType.keyboard
            : type == ChatPanelType.none
            ? ChatBottomPanelType.none
            : ChatBottomPanelType.other,
        data: type,
        forceHandleFocus: isSwitchToEmojiPanel
            ? ChatBottomHandleFocus.requestFocus
            : ChatBottomHandleFocus.none,
      );
    }

    if (isUpdated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        applyPanelType();
      });
    } else {
      applyPanelType();
    }
  }

  /// 同步容器回调到 [currentPanelType]。
  void onPanelTypeChange(ChatBottomPanelType panelType, ChatPanelType? data) {
    switch (panelType) {
      case ChatBottomPanelType.none:
        currentPanelType = ChatPanelType.none;
      case ChatBottomPanelType.keyboard:
        currentPanelType = ChatPanelType.keyboard;
      case ChatBottomPanelType.other:
        if (data == null) {
          return;
        }
        currentPanelType = data;
    }
    onUpdate();
  }

  /// 更新输入框只读态；有变化时刷新界面。
  bool updateInputView({required bool isReadOnly}) {
    if (readOnly == isReadOnly) {
      return false;
    }
    readOnly = isReadOnly;
    onUpdate();
    return true;
  }

  /// 表情面板下点输入框：切回系统键盘。
  void handleInputViewOnPointerUp() {
    if (readOnly) {
      updatePanelType(ChatPanelType.keyboard);
    }
  }

  /// 点表情按钮：表情 ↔ 键盘。
  void handleEmojiBtnClick() {
    updatePanelType(
      currentPanelType == ChatPanelType.emoji
          ? ChatPanelType.keyboard
          : ChatPanelType.emoji,
    );
  }

  /// 把文本插入到输入框光标处。
  void insertText({
    required TextEditingController textController,
    required String text,
  }) {
    final value = textController.text;
    final selection = textController.selection;
    final start = selection.isValid ? selection.start : value.length;
    final end = selection.isValid ? selection.end : value.length;
    final safeStart = start.clamp(0, value.length).toInt();
    final safeEnd = end.clamp(0, value.length).toInt();
    final newText = value.replaceRange(safeStart, safeEnd, text);
    textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: safeStart + text.length),
    );
  }
}
