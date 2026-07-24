import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:all_flutter0709/core/account/account.dart';
import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:all_flutter0709/core/push/chat_push_log.dart';
import 'package:all_flutter0709/features/conversation/data/chat_local_data_source.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_summary.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:qiniu_flutter_sdk/qiniu_flutter_sdk.dart';
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
    dio: HttpClient.instance.dio,
  );
});

class ConversationRepository {
  ConversationRepository({
    required ChatLocalDataSource localDataSource,
    required Dio dio,
  }) : _localDataSource = localDataSource,
       _dio = dio;

  static const _chatTypeSingle = 1;
  static const _qiniuTokenApi = '/api/qiniu/uploadtoken';
  static const _messagePullApi = '/api/message/pull';
  static const _messageSendApi = '/api/chat/send';
  static const _modifyUserApi = '/api/user/modifyarray';

  final ChatLocalDataSource _localDataSource;
  final Dio _dio;
  final Uuid _uuid = const Uuid();
  final Storage _qiniuStorage = Storage();

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
    final response = await _dio.get<Map<String, dynamic>>(_messagePullApi);
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

  Future<void> updatePushClientId({
    required String clientId,
    required AccountModel account,
  }) async {
    if (clientId.trim().isEmpty || clientId == account.cid) {
      return;
    }

    final response = await _dio.post<Map<String, dynamic>>(
      _modifyUserApi,
      data: {'cid': clientId},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }

    final result = ApiResponse<void>.fromJson(json);
    if (!result.success) {
      throw Exception(result.message.isEmpty ? 'CID 同步失败' : result.message);
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
      final response = await _dio.post<Map<String, dynamic>>(
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
        options: Options(contentType: Headers.formUrlEncodedContentType),
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
    } on DioException catch (error) {
      ChatSendLog.d(
        'chat/send DioException type=${error.type} '
        'status=${error.response?.statusCode} '
        'data=${error.response?.data} message=${error.message}',
      );
      rethrow;
    }
  }

  /// 对齐 iTopicX：用七牛官方 SDK 上传（自动选对区域，如 up-z2）。
  Future<void> _uploadImageToQiniu({
    required String userId,
    required String clientMessageId,
    required String filePath,
    required String filename,
  }) async {
    ChatSendLog.d('请求上传凭证 $_qiniuTokenApi');
    final token = await _fetchQiniuUploadToken();
    ChatSendLog.d('拿到上传凭证 length=${token.length}');

    final putController = PutController();
    putController.addProgressListener((percent) {
      final progress = (percent * 95).round().clamp(1, 95);
      unawaited(
        _localDataSource.updateUploadProgress(
          userId,
          clientMessageId,
          progress,
        ),
      );
    });

    ChatSendLog.d('七牛 SDK putFile key=$filename path=$filePath');
    try {
      final response = await _qiniuStorage.putFile(
        File(filePath),
        token,
        options: PutOptions(key: filename, controller: putController),
      );
      ChatSendLog.d(
        '七牛 SDK 上传成功 key=${response.key} hash=${response.hash} '
        'raw=${response.rawData}',
      );
    } catch (error, stackTrace) {
      ChatSendLog.d('七牛 SDK 上传失败: $error');
      ChatSendLog.d('$stackTrace');
      rethrow;
    }
  }

  Future<String> _fetchQiniuUploadToken() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(_qiniuTokenApi);
      final json = response.data;
      ChatSendLog.d('uploadtoken 原始响应: $json');
      if (json == null) {
        throw Exception('上传凭证为空');
      }

      final result = ApiResponse<Map<String, dynamic>>.fromJson(
        json,
        (dataJson) => (dataJson as Map).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
      if (!result.success) {
        throw Exception(
          result.message.isEmpty ? '上传凭证获取失败' : result.message,
        );
      }

      final token = result.data?['token']?.toString() ?? '';
      if (token.isEmpty) {
        throw Exception('上传凭证为空');
      }
      return token;
    } on DioException catch (error) {
      ChatSendLog.d(
        '获取 uploadtoken 失败 type=${error.type} '
        'status=${error.response?.statusCode} '
        'data=${error.response?.data} message=${error.message}',
      );
      rethrow;
    }
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
