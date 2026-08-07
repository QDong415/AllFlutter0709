import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:all_flutter0709/core/account/account.dart';
import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:all_flutter0709/core/push/chat_push_log.dart';
import 'package:all_flutter0709/core/qiniu/qiniu_upload_service.dart';
import 'package:all_flutter0709/features/conversation/data/chat_local_data_source.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_summary.dart';
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
    return inserted;
  }

  Future<ConversationMessage> createPendingTextMessage({
    required AccountModel account,
    required String conversationId,
    required String text,
    String peerName = '',
    String peerAvatar = '',
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

  /// 将当前登录账号绑定到个推 CID（`POST /api/user/modifyarray`）。
  ///
  /// 绑定成功后会再请求 [notifyDoRegAction]，与原生一致。
  Future<void> updatePushClientId({
    required String clientId,
    required AccountModel account,
  }) async {
    if (clientId.trim().isEmpty || clientId == account.cid) {
      return;
    }

    final response = await HttpClient.instance.post(
      _modifyUserApi,
      data: {'cid': clientId},
    );
    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }

    final result = ApiResponse<void>.fromJson(json);
    if (!result.success) {
      throw Exception(result.message.isEmpty ? 'CID 同步失败' : result.message);
    }

    // CID 绑定成功后通知 PHP：可推送小秘书默认消息等注册后续动作
    await notifyDoRegAction();
  }

  /// 通知服务端执行注册后续动作（`POST /api/user/doregaction`）。
  Future<void> notifyDoRegAction() async {
    try {
      await HttpClient.instance.post(
        _doRegActionApi,
        data: <String, dynamic>{},
      );
    } catch (_) {
    }
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
