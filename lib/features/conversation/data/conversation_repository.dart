import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:all_flutter0709/core/account/account.dart';
import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:all_flutter0709/core/push/chat_push_log.dart';
import 'package:all_flutter0709/core/qiniu/qiniu_upload_service.dart';
import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:all_flutter0709/features/conversation/data/chat_local_data_source.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_summary.dart';
import 'package:all_flutter0709/features/conversation/data/chat_voice_file_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

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
       _qiniuUploadService = qiniuUploadService;

  static const _chatTypeSingle = 1;
  static const _messagePullApi = '/api/message/pull';
  static const _messageSendApi = '/api/chat/send';
  static const _modifyUserApi = '/api/user/modifyarray';
  static const _doRegActionApi = '/api/user/doregaction';

  final ChatLocalDataSource _localDataSource;
  final QiniuUploadService _qiniuUploadService;
  final Uuid _uuid = const Uuid();

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
    required String clientMessageId,
    required int msgId,
  }) {
    return _localDataSource.deleteMessage(
      userId: userId,
      clientMessageId: clientMessageId,
      msgId: msgId,
    );
  }

  Future<int> syncPulledMessages(String userId) async {
    ChatPushLog.d('message/pull 请求 userId=$userId');
    final response = await HttpClient.instance.get(_messagePullApi);
    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }

    final result = ApiResponse<List<ConversationMessage>>.fromJson(json, (
      dataJson,
    ) {
      if (dataJson is! List) {
        return const <ConversationMessage>[];
      }
      return dataJson
          .whereType<Map>()
          .map(
            (item) => ConversationMessage.fromApiJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(growable: false);
    });
    if (!result.success) {
      ChatPushLog.d('message/pull 失败: ${result.message}');
      throw Exception(result.message.isEmpty ? '拉取消息失败' : result.message);
    }

    final messages = result.data ?? const <ConversationMessage>[];
    ChatPushLog.d('message/pull 返回 ${messages.length} 条');
    if (messages.isEmpty) {
      return 0;
    }
    final inserted = await _localDataSource.insertMessages(userId, messages);
    ChatPushLog.d('message/pull 新写入 $inserted 条（含去重跳过）');
    await ensureLocalVoiceFiles(userId, messages);
    return inserted;
  }

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
      clientMessageId: _uuid.v4(),
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
    await _localDataSource.insertMessage(account.userId, message);
    final saved = await _localDataSource.findMessageByClientId(
      account.userId,
      message.clientMessageId,
    );
    return saved ?? message;
  }

  Future<void> sendPendingTextMessage({
    required AccountModel account,
    required ConversationMessage message,
  }) async {
    try {
      await _sendChatMessage(
        targetId: message.conversationId,
        content: message.content,
        type: message.type,
        subtype: message.messageType.subtype,
        filename: message.filename,
        extend: message.extend,
        username: account.name,
      );
      await _localDataSource.updateMessageStatus(
        account.userId,
        message.clientMessageId,
        ConversationMessageStatus.sent,
      );
    } catch (_) {
      await _localDataSource.updateMessageStatus(
        account.userId,
        message.clientMessageId,
        ConversationMessageStatus.failed,
      );
      rethrow;
    }
  }

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
    final message = ConversationMessage(
      msgId: 0,
      clientMessageId: _uuid.v4(),
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
      localFilePath: imageFile.path,
      otherUserType: peerUserType,
    );
    await _localDataSource.insertMessage(account.userId, message);
    final saved = await _localDataSource.findMessageByClientId(
      account.userId,
      message.clientMessageId,
    );
    return saved ?? message;
  }

  Future<void> sendPendingImageMessage({
    required AccountModel account,
    required ConversationMessage message,
  }) async {
    ChatSendLog.d(
      '发图开始 clientId=${message.clientMessageId} '
      'file=${message.localFilePath} key=${message.filename} '
      'size=${message.extend}',
    );
    try {
      final file = File(message.localFilePath);
      final exists = await file.exists();
      final length = exists ? await file.length() : -1;
      ChatSendLog.d('本地文件 exists=$exists bytes=$length');

      ChatSendLog.d('开始上传七牛...');
      await _uploadImageToQiniu(
        userId: account.userId,
        clientMessageId: message.clientMessageId,
        filePath: message.localFilePath,
        filename: message.filename,
      );
      ChatSendLog.d('七牛上传成功 key=${message.filename}');

      await _localDataSource.updateUploadProgress(
        account.userId,
        message.clientMessageId,
        100,
      );

      ChatSendLog.d('开始调用 /api/chat/send ...');
      await _sendChatMessage(
        targetId: message.conversationId,
        content: message.content,
        type: message.type,
        subtype: message.messageType.subtype,
        filename: message.filename,
        extend: message.extend,
        username: account.name,
      );
      ChatSendLog.d('chat/send 成功');

      await _localDataSource.updateMessageStatus(
        account.userId,
        message.clientMessageId,
        ConversationMessageStatus.sent,
      );
    } catch (error, stackTrace) {
      ChatSendLog.d('发图失败: $error');
      ChatSendLog.d('$stackTrace');
      await _localDataSource.updateMessageStatus(
        account.userId,
        message.clientMessageId,
        ConversationMessageStatus.failed,
      );
      rethrow;
    }
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
  }) async {
    final message = ConversationMessage(
      msgId: 0,
      clientMessageId: _uuid.v4(),
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
    await _localDataSource.insertMessage(account.userId, message);
    final saved = await _localDataSource.findMessageByClientId(
      account.userId,
      message.clientMessageId,
    );
    return saved ?? message;
  }

  /// 上传语音到七牛并调用 `/api/chat/send`。
  Future<void> sendPendingVoiceMessage({
    required AccountModel account,
    required ConversationMessage message,
  }) async {
    ChatSendLog.d(
      '发语音开始 clientId=${message.clientMessageId} '
      'file=${message.localFilePath} key=${message.filename} '
      'extend=${message.extend}',
    );
    try {
      final file = File(message.localFilePath);
      final exists = await file.exists();
      final length = exists ? await file.length() : -1;
      ChatSendLog.d('本地语音 exists=$exists bytes=$length');

      ChatSendLog.d('开始上传七牛...');
      await _uploadImageToQiniu(
        userId: account.userId,
        clientMessageId: message.clientMessageId,
        filePath: message.localFilePath,
        filename: message.filename,
      );
      ChatSendLog.d('七牛上传成功 key=${message.filename}');

      await _localDataSource.updateUploadProgress(
        account.userId,
        message.clientMessageId,
        100,
      );

      ChatSendLog.d('开始调用 /api/chat/send ...');
      await _sendChatMessage(
        targetId: message.conversationId,
        content: message.content,
        type: message.type,
        subtype: message.messageType.subtype,
        filename: message.filename,
        extend: message.extend,
        username: account.name,
      );
      ChatSendLog.d('语音 chat/send 成功');

      await _localDataSource.updateMessageStatus(
        account.userId,
        message.clientMessageId,
        ConversationMessageStatus.sent,
      );
    } catch (error, stackTrace) {
      ChatSendLog.d('发语音失败: $error');
      ChatSendLog.d('$stackTrace');
      await _localDataSource.updateMessageStatus(
        account.userId,
        message.clientMessageId,
        ConversationMessageStatus.failed,
      );
      rethrow;
    }
  }

  /// 把语音文件下载到本地 filename，对齐 Android `downLoadFile`。
  Future<void> ensureLocalVoiceFiles(
    String userId,
    List<ConversationMessage> messages,
  ) async {
    for (final message in messages) {
      if (message.messageType != ConversationMessageType.voice) {
        continue;
      }
      final filename = message.filename.trim();
      if (filename.isEmpty) {
        continue;
      }

      final localPath = await ChatVoiceFileStore.pathForFileName(filename);
      final localFile = File(localPath);
      if (await localFile.exists()) {
        if (message.localFilePath != localPath) {
          await _localDataSource.updateLocalFilePath(
            userId: userId,
            localFilePath: localPath,
            msgId: message.msgId,
            clientMessageId: message.clientMessageId,
          );
        }
        continue;
      }

      final url = ValueUtil.getQiniuUrlByFileName(filename, keepOriginal: true);
      if (url == null || url.isEmpty) {
        continue;
      }

      try {
        ChatSendLog.d('下载语音 msgid=${message.msgId} url=$url');
        final downloader = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 60),
            followRedirects: true,
          ),
        );
        await downloader.download(url, localPath);
        await _localDataSource.updateLocalFilePath(
          userId: userId,
          localFilePath: localPath,
          msgId: message.msgId,
          clientMessageId: message.clientMessageId,
        );
        ChatSendLog.d('语音下载完成 msgid=${message.msgId} path=$localPath');
      } catch (error) {
        ChatSendLog.d('语音下载失败 msgid=${message.msgId}: $error');
        if (!message.isSender && message.msgId > 0) {
          await _localDataSource.updateMessageStatusByMsgId(
            userId,
            message.msgId,
            ConversationMessageStatus.failed,
          );
        }
      }
    }
  }

  /// 标记语音已播放，对齐 Android 更新 extend.hadplay。
  Future<void> markVoicePlayed({
    required String userId,
    required int msgId,
    required int durationSeconds,
  }) async {
    if (msgId <= 0) {
      return;
    }
    await _localDataSource.updateMessageExtend(
      userId: userId,
      msgId: msgId,
      extend: ConversationMessage.voiceExtendJson(
        durationSeconds: durationSeconds,
        hadPlay: true,
      ),
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

  /// 通知服务端执行注册后续动作（`POST /api/user/doregaction`）。
  Future<void> notifyDoRegAction() async {
    try {
      await HttpClient.instance.post(
        _doRegActionApi,
        data: <String, dynamic>{},
      );
    } catch (_) {}
  }

  Future<void> _sendChatMessage({
    required String targetId,
    required String content,
    required int type,
    required int subtype,
    required String filename,
    required String extend,
    required String username,
  }) async {
    ChatSendLog.d(
      'chat/send targetId=$targetId type=$type subtype=$subtype '
      'filename=$filename extend=$extend',
    );
    try {
      final response = await HttpClient.instance.post(
        _messageSendApi,
        data: {
          'targetid': targetId,
          'content': content,
          'type': '$type',
          'subtype': '$subtype',
          'filename': filename,
          'extend': extend,
          'username': username,
        },
      );
      final json = response.data;
      ChatSendLog.d('chat/send 响应: $json');
      if (json == null) {
        throw Exception('服务器返回为空');
      }

      final result = ApiResponse<void>.fromJson(json);
      if (!result.success) {
        throw Exception(result.message.isEmpty ? '发送失败' : result.message);
      }
    } catch (error) {
      ChatSendLog.d('chat/send 失败: $error');
      rethrow;
    }
  }

  /// 上传聊天图片到七牛，并把进度写入本地消息（1~95）。
  Future<void> _uploadImageToQiniu({
    required String userId,
    required String clientMessageId,
    required String filePath,
    required String filename,
  }) async {
    await _qiniuUploadService.uploadFile(
      file: File(filePath),
      key: filename,
      onProgress: (percent) {
        final progress = (percent * 95).round().clamp(1, 95);
        unawaited(
          _localDataSource.updateUploadProgress(
            userId,
            clientMessageId,
            progress,
          ),
        );
      },
    );
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

  int _nowSeconds() => DateTime.now().millisecondsSinceEpoch ~/ 1000;
}
