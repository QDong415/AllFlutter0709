import 'dart:async';

import 'package:all_flutter0709/features/conversation/presentation/models/chat_item.dart';
import 'package:all_flutter0709/features/conversation/presentation/models/chat_message_interaction.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_bubble_action_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 气泡长按：选中高亮、菜单定位、复制与删除。
class ChatBubbleMenuHelper {
  ChatBubbleMenuHelper({
    required this.onUpdate,
    required this.deleteMessage,
    this.stopIfPlaying,
    this.onTip,
  });

  /// 选中态变化时刷新界面。
  final VoidCallback onUpdate;

  /// 删除本地消息。
  final Future<void> Function(MessageItem message) deleteMessage;

  /// 若正在播放该语音条则停止。
  final Future<void> Function(String messageId)? stopIfPlaying;

  /// 复制成功 / 删除失败时的轻提示。
  final ValueChanged<String>? onTip;

  /// 菜单相对此 Stack 定位。
  final overlayStackKey = GlobalKey();

  String? _selectedMessageId;
  Rect? _menuAnchorRect;
  MessageItem? _menuMessage;

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
        onDelete: () {
          unawaited(deleteSelected());
        },
        onDismiss: hide,
      ),
    );
  }

  String _copyTextOf(MessageItem item) {
    return switch (item) {
      TextMessage(:final text) => text,
      ImageMessage() => '[图片]',
      VoiceMessage() => '[语音消息]',
    };
  }
}
