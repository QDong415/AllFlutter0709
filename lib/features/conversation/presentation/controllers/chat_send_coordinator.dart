import 'dart:io';

import 'package:all_flutter0709/core/account/account.dart';
import 'package:all_flutter0709/core/push/chat_push_log.dart';
import 'package:all_flutter0709/features/conversation/data/conversation_repository.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';
import 'package:all_flutter0709/features/conversation/presentation/controllers/conversation_message_store.dart';
import 'package:flutter/material.dart';

/// 聊天发送的展示层状态协调器。
///
/// 负责调用 [ConversationRepository] 发起发送流程，将 pending、上传进度及
/// sent/failed 结果增量同步到 [ConversationMessageStore]，并刷新会话摘要；
/// 不直接访问 HTTP、七牛或本地数据库，也不负责具体 Widget 的构建。
class ChatSendCoordinator {
  const ChatSendCoordinator({
    required ConversationRepository repository,
    required ConversationMessageStore messageStore,
    required Future<void> Function() refreshConversations,
  }) : _repository = repository,
       _messageStore = messageStore,
       _refreshConversations = refreshConversations;

  final ConversationRepository _repository;
  final ConversationMessageStore _messageStore;
  final Future<void> Function() _refreshConversations;

  /// 创建并发送文本消息。
  Future<void> sendText({
    required AccountModel account,
    required String conversationId,
    required String text,
    String peerName = '',
    String peerAvatar = '',
    int peerUserType = 0,
  }) async {
    final message = await _repository.createPendingTextMessage(
      account: account,
      conversationId: conversationId,
      text: text,
      peerName: peerName,
      peerAvatar: peerAvatar,
      peerUserType: peerUserType,
    );
    _messageStore.append(conversationId, message);
    await _refreshConversations();

    try {
      final sentMessage = await _repository.sendPendingTextMessage(
        account: account,
        message: message,
      );
      _messageStore.replace(conversationId, sentMessage);
    } catch (_) {
      _markFailed(conversationId, message.clientMessageId);
      rethrow;
    } finally {
      await _refreshConversations();
    }
  }

  /// 创建、上传并发送图片消息。
  Future<void> sendImage({
    required AccountModel account,
    required String conversationId,
    required File imageFile,
    required Size imageSize,
    String peerName = '',
    String peerAvatar = '',
    int peerUserType = 0,
  }) async {
    ChatSendLog.d(
      'Controller 发图 conversationId=$conversationId '
      'path=${imageFile.path} size=${imageSize.width}x${imageSize.height}',
    );
    final message = await _repository.createPendingImageMessage(
      account: account,
      conversationId: conversationId,
      imageFile: imageFile,
      imageSize: imageSize,
      peerName: peerName,
      peerAvatar: peerAvatar,
      peerUserType: peerUserType,
    );
    _messageStore.append(conversationId, message);
    await _refreshConversations();

    try {
      final sentMessage = await _repository.sendPendingImageMessage(
        account: account,
        message: message,
        onProgress: (progress) {
          _messageStore.updateUploadProgress(
            conversationId: conversationId,
            clientMessageId: message.clientMessageId,
            progress: progress,
          );
        },
      );
      _messageStore.replace(conversationId, sentMessage);
      ChatSendLog.d('Controller 发图完成');
    } catch (error, stackTrace) {
      _markFailed(conversationId, message.clientMessageId);
      ChatSendLog.d('Controller 发图失败: $error');
      ChatSendLog.d('$stackTrace');
      rethrow;
    } finally {
      await _refreshConversations();
    }
  }

  /// 创建、上传并发送语音消息。
  Future<void> sendVoice({
    required AccountModel account,
    required String conversationId,
    required File audioFile,
    required String filename,
    required int durationSeconds,
    String peerName = '',
    String peerAvatar = '',
    int peerUserType = 0,
  }) async {
    ChatSendLog.d(
      'Controller 发语音 conversationId=$conversationId '
      'file=${audioFile.path} duration=$durationSeconds filename=$filename',
    );
    final message = await _repository.createPendingVoiceMessage(
      account: account,
      conversationId: conversationId,
      audioFile: audioFile,
      filename: filename,
      durationSeconds: durationSeconds,
      peerName: peerName,
      peerAvatar: peerAvatar,
      peerUserType: peerUserType,
    );
    _messageStore.append(conversationId, message);
    await _refreshConversations();

    try {
      final sentMessage = await _repository.sendPendingVoiceMessage(
        account: account,
        message: message,
        onProgress: (progress) {
          _messageStore.updateUploadProgress(
            conversationId: conversationId,
            clientMessageId: message.clientMessageId,
            progress: progress,
          );
        },
      );
      _messageStore.replace(conversationId, sentMessage);
      ChatSendLog.d('Controller 发语音完成');
    } catch (error, stackTrace) {
      _markFailed(conversationId, message.clientMessageId);
      ChatSendLog.d('Controller 发语音失败: $error');
      ChatSendLog.d('$stackTrace');
      rethrow;
    } finally {
      await _refreshConversations();
    }
  }

  void _markFailed(String conversationId, int clientMessageId) {
    _messageStore.update(
      conversationId: conversationId,
      clientMessageId: clientMessageId,
      transform: (message) =>
          message.copyWith(status: ConversationMessageStatus.failed),
    );
  }
}
