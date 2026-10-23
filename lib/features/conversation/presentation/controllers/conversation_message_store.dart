import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 会话消息内存仓库：按会话隔离状态，并提供单条消息增量更新。
class ConversationMessageStore {
  final Map<String, ValueNotifier<AsyncValue<List<ConversationMessage>>>>
  _messagesNotifierMap = {};

  /// 读取指定会话当前状态。
  AsyncValue<List<ConversationMessage>> stateOf(String conversationId) {
    return _notifierOf(conversationId).value;
  }

  /// 监听指定会话，其他会话和会话列表变化不会触发通知。
  ValueListenable<AsyncValue<List<ConversationMessage>>> listenableOf(
    String conversationId,
  ) {
    return _notifierOf(conversationId);
  }

  /// 设置指定会话的完整状态，用于首次加载和数据库同步。
  void setState(
    String conversationId,
    AsyncValue<List<ConversationMessage>> state,
  ) {
    _notifierOf(conversationId).value = state;
  }

  /// 追加一条本地 pending 或新收到的消息。
  void append(String conversationId, ConversationMessage message) {
    final currentState = stateOf(conversationId);
    final messageList = currentState is AsyncData<List<ConversationMessage>>
        ? currentState.value
        : const <ConversationMessage>[];
    setState(
      conversationId,
      AsyncValue.data(
        List<ConversationMessage>.from(messageList)..add(message),
      ),
    );
  }

  /// 按客户端消息 ID 替换一条消息。
  void replace(String conversationId, ConversationMessage message) {
    update(
      conversationId: conversationId,
      clientMessageId: message.clientMessageId,
      transform: (_) => message,
    );
  }

  /// 按客户端消息 ID 增量更新一条消息。
  void update({
    required String conversationId,
    required int clientMessageId,
    required ConversationMessage Function(ConversationMessage message)
    transform,
  }) {
    final currentState = stateOf(conversationId);
    if (currentState is! AsyncData<List<ConversationMessage>>) {
      return;
    }
    var changed = false;
    final messageList = currentState.value
        .map((message) {
          if (message.clientMessageId != clientMessageId) {
            return message;
          }
          final updatedMessage = transform(message);
          if (!identical(updatedMessage, message)) {
            changed = true;
          }
          return updatedMessage;
        })
        .toList(growable: false);
    if (changed) {
      setState(conversationId, AsyncValue.data(messageList));
    }
  }

  /// 优先按客户端 ID、否则按服务端 ID 更新消息。
  void updateByIdentity({
    required String conversationId,
    required int clientMessageId,
    required int msgId,
    required ConversationMessage Function(ConversationMessage message)
    transform,
  }) {
    final currentState = stateOf(conversationId);
    if (currentState is! AsyncData<List<ConversationMessage>>) {
      return;
    }
    var changed = false;
    final messageList = currentState.value
        .map((message) {
          final matched = clientMessageId > 0
              ? message.clientMessageId == clientMessageId
              : msgId > 0 && message.msgId == msgId;
          if (!matched) {
            return message;
          }
          final updatedMessage = transform(message);
          if (!identical(updatedMessage, message)) {
            changed = true;
          }
          return updatedMessage;
        })
        .toList(growable: false);
    if (changed) {
      setState(conversationId, AsyncValue.data(messageList));
    }
  }

  /// 删除客户端 ID 或服务端 ID 匹配的消息。
  void remove({
    required String conversationId,
    required int clientMessageId,
    required int msgId,
  }) {
    final currentState = stateOf(conversationId);
    if (currentState is! AsyncData<List<ConversationMessage>>) {
      return;
    }
    setState(
      conversationId,
      AsyncValue.data(
        currentState.value
            .where((message) {
              if (clientMessageId > 0) {
                return message.clientMessageId != clientMessageId;
              }
              if (msgId != 0) {
                return message.msgId != msgId;
              }
              return true;
            })
            .toList(growable: false),
      ),
    );
  }

  /// 上传进度每跨过 5% 才通知，避免高频回调持续重建可见列表。
  void updateUploadProgress({
    required String conversationId,
    required int clientMessageId,
    required int progress,
  }) {
    update(
      conversationId: conversationId,
      clientMessageId: clientMessageId,
      transform: (message) {
        if (progress < 95 && progress - message.uploadProgress < 5) {
          return message;
        }
        return message.copyWith(uploadProgress: progress);
      },
    );
  }

  /// 清空全部已创建会话，保留 notifier 以免正在监听的页面失联。
  void clearAll() {
    for (final entry in _messagesNotifierMap.entries) {
      entry.value.value = const AsyncValue.data(<ConversationMessage>[]);
    }
  }

  /// 释放全部会话监听器。
  void dispose() {
    for (final notifier in _messagesNotifierMap.values) {
      notifier.dispose();
    }
    _messagesNotifierMap.clear();
  }

  ValueNotifier<AsyncValue<List<ConversationMessage>>> _notifierOf(
    String conversationId,
  ) {
    return _messagesNotifierMap.putIfAbsent(
      conversationId,
      () => ValueNotifier<AsyncValue<List<ConversationMessage>>>(
        const AsyncValue.loading(),
      ),
    );
  }
}
