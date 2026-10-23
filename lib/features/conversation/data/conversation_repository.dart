import 'dart:io';

import 'package:all_flutter0709/core/account/account.dart';
import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:all_flutter0709/core/push/chat_push_log.dart';
import 'package:all_flutter0709/core/qiniu/qiniu_upload_service.dart';
import 'package:all_flutter0709/features/conversation/data/chat_local_data_source.dart';
import 'package:all_flutter0709/features/conversation/data/chat_message_sync_service.dart';
import 'package:all_flutter0709/features/conversation/data/chat_message_sender.dart';
import 'package:all_flutter0709/features/conversation/data/chat_voice_service.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatLocalDataSourceProvider = Provider<ChatLocalDataSource>((ref) {
  final dataSource = ChatLocalDataSource();
  //当 chatLocalDataSourceProvider 不再被使用、Riverpod 要丢掉这个实例时 → 调用 dataSource.close()
  ref.onDispose(dataSource.close);
  return dataSource;
});

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return ConversationRepository(
    localDataSource: ref.watch(chatLocalDataSourceProvider),
    qiniuUploadService: ref.watch(qiniuUploadServiceProvider),
  );
});

/// 会话数据仓库：本地消息读写、拉取/发送聊天消息。
class ConversationRepository {
  ConversationRepository({
    required ChatLocalDataSource localDataSource,
    required QiniuUploadService qiniuUploadService,
  }) : _localDataSource = localDataSource,
       _voiceService = ChatVoiceService(localDataSource: localDataSource),
       _messageDeliveryService = ChatMessageDeliveryService(
         localDataSource: localDataSource,
         qiniuUploadService: qiniuUploadService,
       ) {
    _messageSyncService = ChatMessageSyncService(
      localDataSource: localDataSource,
      voiceService: _voiceService,
    );
  }

  static const _modifyUserApi = '/api/user/modifyarray';
  static const _doRegActionApi = '/api/user/doregaction';

  final ChatLocalDataSource _localDataSource;
  final ChatVoiceService _voiceService;
  final ChatMessageDeliveryService _messageDeliveryService;
  late final ChatMessageSyncService _messageSyncService;

  Future<List<ConversationSummary>> getConversationList(String userId) {
    return _localDataSource.getConversationList(userId);
  }

  Future<List<ConversationMessage>> getMessages(
    String userId,
    String conversationId,
  ) {
    return _localDataSource.getMessages(userId, conversationId);
  }

  Future<int> getTotalUnreadCount(String userId) {
    return _localDataSource.getTotalUnreadCount(userId);
  }

  Future<void> markConversationRead(String userId, String conversationId) {
    return _localDataSource.markConversationRead(userId, conversationId);
  }

  /// 删除指定会话的全部本地消息。
  Future<void> deleteConversation(String userId, String conversationId) {
    return _localDataSource.deleteConversation(userId, conversationId);
  }

  /// 删除单条本地消息。
  Future<void> deleteMessage({
    required String userId,
    required int clientMessageId,
    required int msgId,
  }) {
    return _localDataSource.deleteMessage(
      userId: userId,
      clientMessageId: clientMessageId,
      msgId: msgId,
    );
  }

  Future<int> syncPulledMessages(String userId) {
    return _messageSyncService.syncPulledMessages(userId);
  }

  Future<ConversationMessage> createPendingTextMessage({
    required AccountModel account,
    required String conversationId,
    required String text,
    String peerName = '',
    String peerAvatar = '',
    int peerUserType = 0,
  }) {
    return _messageDeliveryService.createPendingTextMessage(
      account: account,
      conversationId: conversationId,
      text: text,
      peerName: peerName,
      peerAvatar: peerAvatar,
      peerUserType: peerUserType,
    );
  }

  /// 发送待处理文本消息，并返回可直接更新界面的已发送消息。
  Future<ConversationMessage> sendPendingTextMessage({
    required AccountModel account,
    required ConversationMessage message,
  }) {
    return _messageDeliveryService.sendPendingTextMessage(
      account: account,
      message: message,
    );
  }

  Future<ConversationMessage> createPendingImageMessage({
    required AccountModel account,
    required String conversationId,
    required File imageFile,
    required Size imageSize,
    String peerName = '',
    String peerAvatar = '',
    int peerUserType = 0,
  }) {
    return _messageDeliveryService.createPendingImageMessage(
      account: account,
      conversationId: conversationId,
      imageFile: imageFile,
      imageSize: imageSize,
      peerName: peerName,
      peerAvatar: peerAvatar,
      peerUserType: peerUserType,
    );
  }

  /// 上传并发送图片，过程中回传上传进度，成功后返回已发送消息。
  Future<ConversationMessage> sendPendingImageMessage({
    required AccountModel account,
    required ConversationMessage message,
    ValueChanged<int>? onProgress,
  }) {
    return _messageDeliveryService.sendPendingImageMessage(
      account: account,
      message: message,
      onProgress: onProgress,
    );
  }

  /// 创建待发送的语音消息，extend 对齐 Android `duration` / `hadplay`。
  Future<ConversationMessage> createPendingVoiceMessage({
    required AccountModel account,
    required String conversationId,
    required File audioFile,
    required String filename,
    required int durationSeconds,
    String peerName = '',
    String peerAvatar = '',
    int peerUserType = 0,
  }) {
    return _messageDeliveryService.createPendingVoiceMessage(
      account: account,
      conversationId: conversationId,
      audioFile: audioFile,
      filename: filename,
      durationSeconds: durationSeconds,
      peerName: peerName,
      peerAvatar: peerAvatar,
      peerUserType: peerUserType,
    );
  }

  /// 上传语音到七牛并调用 `/api/chat/send`。
  Future<ConversationMessage> sendPendingVoiceMessage({
    required AccountModel account,
    required ConversationMessage message,
    ValueChanged<int>? onProgress,
  }) {
    return _messageDeliveryService.sendPendingVoiceMessage(
      account: account,
      message: message,
      onProgress: onProgress,
    );
  }

  /// 把语音文件下载到本地 filename，对齐 Android `downLoadFile`。
  Future<void> ensureLocalVoiceFiles(
    String userId,
    List<ConversationMessage> messages,
  ) {
    return _voiceService.ensureLocalFiles(userId, messages);
  }

  /// 标记语音已播放，对齐 Android 更新 extend.hadplay。
  Future<void> markVoicePlayed({
    required String userId,
    required int msgId,
    required int durationSeconds,
  }) {
    return _voiceService.markPlayed(
      userId: userId,
      msgId: msgId,
      durationSeconds: durationSeconds,
    );
  }

  /// 将当前登录账号绑定到个推 CID（`POST /api/user/modifyarray`）。
  Future<void> updatePushClientId({
    required String clientId,
    required AccountModel account,
  }) async {
    final trimmed = clientId.trim();
    if (trimmed.isEmpty) {
      return;
    }

    ChatPushLog.d('上报 CID modifyarray cid=$trimmed');
    final response = await HttpClient.instance.post(
      _modifyUserApi,
      data: {'cid': trimmed},
    );
    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }

    final result = ApiResponse<void>.fromJson(json);
    if (!result.success) {
      throw Exception(result.message.isEmpty ? 'CID 同步失败' : result.message);
    }

    final data = json['data'];
    final serverCid = data is Map ? data['cid']?.toString() ?? '' : '';
    if (serverCid != trimmed) {
      throw Exception('CID 写入未生效，服务器仍为 ${serverCid.isEmpty ? '空' : serverCid}');
    }
  }

  /// 撤回已发送的消息：先请求服务端清空原文，成功后再改本地行。
  Future<void> recallMessage({
    required String userId,
    required int clientMessageId,
    required int msgId,
  }) {
    return _messageDeliveryService.recallMessage(
      userId: userId,
      clientMessageId: clientMessageId,
      msgId: msgId,
    );
  }

  /// 通知服务端执行注册后续动作（`POST /api/user/doregaction`）。
  Future<void> notifyDoRegAction() async {
    try {
      await HttpClient.instance.post(
        _doRegActionApi,
        data: <String, dynamic>{},
      );
    } catch (_) {}
  }
}
