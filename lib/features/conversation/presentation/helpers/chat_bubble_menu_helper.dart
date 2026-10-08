import 'dart:async';

import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';
import 'package:all_flutter0709/features/conversation/presentation/models/chat_item.dart';
import 'package:all_flutter0709/features/conversation/presentation/models/chat_message_interaction.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_bubble_action_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 气泡长按：选中高亮、菜单定位、复制、撤回与删除。
class ChatBubbleMenuHelper {
  ChatBubbleMenuHelper({
    required this.onUpdate,
    required this.deleteMessage,
    required this.recallMessage,
    this.stopIfPlaying,
    this.onTip,
  });

  /// 选中态变化时刷新界面。
  final VoidCallback onUpdate;

  /// 删除本地消息。
  final Future<void> Function(MessageItem message) deleteMessage;

  /// 撤回自己发出的消息。
  final Future<void> Function(MessageItem message) recallMessage;

  /// 若正在播放该语音条则停止。
  final Future<void> Function(String messageId)? stopIfPlaying;

  /// 复制成功 / 删除失败时的轻提示。
  final ValueChanged<String>? onTip;

  /// 菜单相对此 Stack 定位。
  final overlayStackKey = GlobalKey();

  String? _selectedMessageId;
  Rect? _menuAnchorRect;
  MessageItem? _menuMessage;
  bool _canRecall = false;

  /// 当前高亮气泡 id；无菜单时为 null。
  String? get selectedMessageId => _selectedMessageId;

  /// 菜单是否正在显示。
  bool get isVisible => _menuAnchorRect != null;

  /// 长按后显示复制/删除菜单。
  void show(ChatBubbleLongPressDetails details) {
    final stackBox =
        overlayStackKey.currentContext?.findRenderObject() as RenderBox?;
    var anchorRect = details.bubbleRect;
    if (stackBox != null && stackBox.hasSize) {
      final localTopLeft = stackBox.globalToLocal(details.bubbleRect.topLeft);
      anchorRect = localTopLeft & details.bubbleRect.size;
    }
    _selectedMessageId = details.item.id;
    _menuAnchorRect = anchorRect;
    _menuMessage = details.item;
    _canRecall = _canRecallMessage(details.item);
    onUpdate();
  }

  /// 收起菜单并取消选中。
  void hide() {
    if (_selectedMessageId == null && _menuAnchorRect == null) {
      return;
    }
    _selectedMessageId = null;
    _menuAnchorRect = null;
    _menuMessage = null;
    _canRecall = false;
    onUpdate();
  }

  /// 复制当前选中气泡文案。
  Future<void> copySelected() async {
    final message = _menuMessage;
    hide();
    if (message == null) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: _copyTextOf(message)));
    onTip?.call('复制成功');
  }

  /// 删除当前选中气泡。
  Future<void> deleteSelected() async {
    final message = _menuMessage;
    hide();
    if (message == null) {
      return;
    }
    await stopIfPlaying?.call(message.id);
    try {
      await deleteMessage(message);
    } catch (_) {
      onTip?.call('删除失败');
    }
  }

  /// 撤回当前选中气泡。
  Future<void> recallSelected() async {
    final message = _menuMessage;
    hide();
    if (message == null) {
      return;
    }
    await stopIfPlaying?.call(message.id);
    try {
      await recallMessage(message);
    } catch (error) {
      onTip?.call(_tipFromError(error));
    }
  }

  /// 菜单浮层；未显示时返回 null。
  Widget? buildOverlay() {
    final anchorRect = _menuAnchorRect;
    if (anchorRect == null) {
      return null;
    }
    return Positioned.fill(
      child: ChatBubbleActionMenu(
        anchorRect: anchorRect,
        onCopy: () {
          unawaited(copySelected());
        },
        onRecall: _canRecall
            ? () {
                unawaited(recallSelected());
              }
            : null,
        onDelete: () {
          unawaited(deleteSelected());
        },
        onDismiss: hide,
      ),
    );
  }

  bool _canRecallMessage(MessageItem item) {
    if (!item.isRight || item.deliveryStatus != MessageDeliveryStatus.sent) {
      return false;
    }
    if (item.msgId <= 0 && item.clientMessageId <= 0) {
      return false;
    }
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return nowSeconds - item.createTimeSeconds <=
        ConversationMessage.recallWindowSeconds;
  }

  String _tipFromError(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '');
    if (text.isEmpty || text.startsWith('DioException')) {
      return '撤回失败';
    }
    return text;
  }

  String _copyTextOf(MessageItem item) {
    return switch (item) {
      TextMessage(:final text) => text,
      ImageMessage() => '[图片]',
      VoiceMessage() => '[语音消息]',
    };
  }
}
