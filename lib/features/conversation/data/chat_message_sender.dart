import 'dart:convert';
import 'dart:io';

import 'package:all_flutter0709/core/account/account.dart';
import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:all_flutter0709/core/push/chat_push_log.dart';
import 'package:all_flutter0709/core/qiniu/qiniu_upload_service.dart';
import 'package:all_flutter0709/features/conversation/data/chat_image_file_store.dart';
import 'package:all_flutter0709/features/conversation/data/chat_local_data_source.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

/// 聊天消息的数据层投递服务。
///
/// 负责创建并保存 pending 消息、上传图片/语音附件、调用发送/撤回接口，
/// 以及把 sent/failed/上传进度写入数据库；不依赖 Widget、界面消息 Store
/// 或页面状态。展示层统一通过 `ConversationRepository` 间接调用本服务。
class ChatMessageDeliveryService {
  ChatMessageDeliveryService({
    required ChatLocalDataSource localDataSource,
    required QiniuUploadService qiniuUploadService,
  }) : _localDataSource = localDataSource,
       _qiniuUploadService = qiniuUploadService;

  static const _chatTypeSingle = 1;
  static const _messageSendApi = '/api/chat/send';
  static const _messageRecallApi = '/api/chat/recall';

  final ChatLocalDataSource _localDataSource;
  final QiniuUploadService _qiniuUploadService;
  int _lastClientMessageMillis = 0;
  int _clientMessageSeq = 0;

  /// 创建并保存待发送文本消息。
  Future<ConversationMessage> createPendingTextMessage({
    required AccountModel account,
    required String conversationId,
    required String text,
    String peerName = '',
    String peerAvatar = '',
    int peerUserType = 0,
  }) async {
    final message = ConversationMessage(
      msgId: 0,
      clientMessageId: _nextClientMessageId(),
      conversationId: conversationId,
      otherUserId: conversationId,
      otherName: peerName,
      otherPhoto: peerAvatar,
      content: text,
      createTimeSeconds: _nowSeconds(),
      status: ConversationMessageStatus.sending,
      type: _chatTypeSingle,
      messageType: ConversationMessageType.text,
      filename: '',
      extend: '',
      isSender: true,
      isRead: true,
      otherUserType: peerUserType,
    );
    return _savePendingMessage(account.userId, message);
  }

  /// 发送待处理文本消息，并返回可直接更新界面的已发送消息。
  Future<ConversationMessage> sendPendingTextMessage({
    required AccountModel account,
    required ConversationMessage message,
  }) async {
    try {
      final msgId = await _sendChatMessage(account: account, message: message);
      await _markSent(account.userId, message.clientMessageId, msgId);
      return message.copyWith(
        msgId: msgId,
        status: ConversationMessageStatus.sent,
      );
    } catch (_) {
      await _markFailed(account.userId, message.clientMessageId);
      rethrow;
    }
  }

  /// 创建并保存待发送图片消息。
  Future<ConversationMessage> createPendingImageMessage({
    required AccountModel account,
    required String conversationId,
    required File imageFile,
    required Size imageSize,
    String peerName = '',
    String peerAvatar = '',
    int peerUserType = 0,
  }) async {
    final filename = _buildImageFileName(
      conversationId: conversationId,
      sourcePath: imageFile.path,
    );
    final persistedFile = await ChatImageFileStore.persist(
      sourceFile: imageFile,
      filename: filename,
    );
    final message = ConversationMessage(
      msgId: 0,
      clientMessageId: _nextClientMessageId(),
      conversationId: conversationId,
      otherUserId: conversationId,
      otherName: peerName,
      otherPhoto: peerAvatar,
      content: '[图片消息]',
      createTimeSeconds: _nowSeconds(),
      status: ConversationMessageStatus.sending,
      type: _chatTypeSingle,
      messageType: ConversationMessageType.image,
      filename: filename,
      extend: jsonEncode({
        'width': imageSize.width.round(),
        'height': imageSize.height.round(),
      }),
      isSender: true,
      isRead: true,
      localFilePath: persistedFile.path,
      otherUserType: peerUserType,
    );
    return _savePendingMessage(account.userId, message);
  }

  /// 上传并发送图片，过程中回传上传进度。
  Future<ConversationMessage> sendPendingImageMessage({
    required AccountModel account,
    required ConversationMessage message,
    ValueChanged<int>? onProgress,
  }) {
    return _sendPendingAttachmentMessage(
      account: account,
      message: message,
      logName: '图片',
      onProgress: onProgress,
    );
  }

  /// 创建并保存待发送语音消息。
  Future<ConversationMessage> createPendingVoiceMessage({
    required AccountModel account,
    required String conversationId,
    required File audioFile,
    required String filename,
    required int durationSeconds,
    String peerName = '',
    String peerAvatar = '',
    int peerUserType = 0,
  }) async {
    final message = ConversationMessage(
      msgId: 0,
      clientMessageId: _nextClientMessageId(),
      conversationId: conversationId,
      otherUserId: conversationId,
      otherName: peerName,
      otherPhoto: peerAvatar,
      content: '[语音消息]',
      createTimeSeconds: _nowSeconds(),
      status: ConversationMessageStatus.sending,
      type: _chatTypeSingle,
      messageType: ConversationMessageType.voice,
      filename: filename,
      extend: ConversationMessage.voiceExtendJson(
        durationSeconds: durationSeconds,
        hadPlay: true,
      ),
      isSender: true,
      isRead: true,
      localFilePath: audioFile.path,
      otherUserType: peerUserType,
    );
    return _savePendingMessage(account.userId, message);
  }

  /// 上传并发送语音，过程中回传上传进度。
  Future<ConversationMessage> sendPendingVoiceMessage({
    required AccountModel account,
    required ConversationMessage message,
    ValueChanged<int>? onProgress,
  }) {
    return _sendPendingAttachmentMessage(
      account: account,
      message: message,
      logName: '语音',
      onProgress: onProgress,
    );
  }

  /// 撤回服务端消息，成功后同步本地状态。
  Future<void> recallMessage({
    required String userId,
    required int clientMessageId,
    required int msgId,
  }) async {
    final response = await HttpClient.instance.post(
      _messageRecallApi,
      data: {'msgid': '$msgId', 'client_messageid': clientMessageId},
    );
    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }
    final result = ApiResponse<void>.fromJson(json);
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '撤回失败' : result.message);
    }
    await _localDataSource.markMessageRecalled(
      userId: userId,
      clientMessageId: clientMessageId,
      msgId: msgId,
    );
  }

  Future<ConversationMessage> _sendPendingAttachmentMessage({
    required AccountModel account,
    required ConversationMessage message,
    required String logName,
    ValueChanged<int>? onProgress,
  }) async {
    ChatSendLog.d(
      '发$logName开始 clientId=${message.clientMessageId} '
      'file=${message.localFilePath} key=${message.filename} '
      'extend=${message.extend}',
    );
    try {
      final file = File(message.localFilePath);
      final exists = await file.exists();
      final length = exists ? await file.length() : -1;
      ChatSendLog.d('本地$logName exists=$exists bytes=$length');

      await _uploadAttachment(
        userId: account.userId,
        message: message,
        onProgress: onProgress,
      );
      await _localDataSource.updateUploadProgress(
        account.userId,
        message.clientMessageId,
        100,
      );

      final msgId = await _sendChatMessage(account: account, message: message);
      await _markSent(account.userId, message.clientMessageId, msgId);
      ChatSendLog.d('$logName chat/send 成功 msgid=$msgId');
      return message.copyWith(
        msgId: msgId,
        status: ConversationMessageStatus.sent,
        uploadProgress: 100,
      );
    } catch (error, stackTrace) {
      ChatSendLog.d('发$logName失败: $error');
      ChatSendLog.d('$stackTrace');
      await _markFailed(account.userId, message.clientMessageId);
      rethrow;
    }
  }

  Future<ConversationMessage> _savePendingMessage(
    String userId,
    ConversationMessage message,
  ) async {
    await _localDataSource.insertMessage(userId, message);
    final saved = await _localDataSource.findMessageByClientId(
      userId,
      message.clientMessageId,
    );
    return saved ?? message;
  }

  Future<int> _sendChatMessage({
    required AccountModel account,
    required ConversationMessage message,
  }) async {
    ChatSendLog.d(
      'chat/send targetId=${message.conversationId} '
      'type=${message.type} subtype=${message.messageType.subtype} '
      'filename=${message.filename} extend=${message.extend}',
    );
    final response = await HttpClient.instance.post(
      _messageSendApi,
      data: {
        'targetid': message.conversationId,
        'content': message.content,
        'type': '${message.type}',
        'subtype': '${message.messageType.subtype}',
        'filename': message.filename,
        'extend': message.extend,
        'username': account.name,
        'client_messageid': message.clientMessageId,
      },
    );
    final json = response.data;
    ChatSendLog.d('chat/send 响应: $json');
    if (json == null) {
      throw Exception('服务器返回为空');
    }
    final result = ApiResponse<int>.fromJson(json, _readMsgId);
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '发送失败' : result.message);
    }
    return result.data ?? 0;
  }

  Future<void> _uploadAttachment({
    required String userId,
    required ConversationMessage message,
    ValueChanged<int>? onProgress,
  }) async {
    // SDK 的进度回调是同步接口，数据库写入改为串行队列；上传结束后等待队列
    // 清空，避免较早的低进度写入晚于 100%，把最终进度覆盖回去。
    var progressWrite = Future<void>.value();
    await _qiniuUploadService.uploadFile(
      file: File(message.localFilePath),
      key: message.filename,
      onProgress: (percent) {
        final progress = (percent * 95).round().clamp(1, 95);
        onProgress?.call(progress);
        progressWrite = progressWrite.then(
          (_) => _localDataSource.updateUploadProgress(
            userId,
            message.clientMessageId,
            progress,
          ),
        );
      },
    );
    await progressWrite;
  }

  Future<void> _markSent(String userId, int clientMessageId, int msgId) {
    return _localDataSource.markMessageSent(
      userId: userId,
      clientMessageId: clientMessageId,
      msgId: msgId,
    );
  }

  Future<void> _markFailed(String userId, int clientMessageId) {
    return _localDataSource.updateMessageStatus(
      userId,
      clientMessageId,
      ConversationMessageStatus.failed,
    );
  }

  int _readMsgId(Object? dataJson) {
    if (dataJson is! Map) {
      return 0;
    }
    final raw = dataJson['msgid'];
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  String _buildImageFileName({
    required String conversationId,
    required String sourcePath,
  }) {
    final extension = path.extension(sourcePath);
    final randomPart = DateTime.now().millisecondsSinceEpoch;
    final suffix = extension.isEmpty ? '.jpg' : extension;
    return '$conversationId-${_nowSeconds()}-$randomPart$suffix';
  }

  int _nextClientMessageId() {
    final millis = DateTime.now().millisecondsSinceEpoch;
    if (millis == _lastClientMessageMillis) {
      _clientMessageSeq = (_clientMessageSeq + 1) % 1000;
    } else {
      _lastClientMessageMillis = millis;
      _clientMessageSeq = 0;
    }
    return millis * 1000 + _clientMessageSeq;
  }

  int _nowSeconds() => DateTime.now().millisecondsSinceEpoch ~/ 1000;
}
