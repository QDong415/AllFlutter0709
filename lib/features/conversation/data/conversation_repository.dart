import 'dart:convert';
import 'dart:io';

import 'package:all_flutter0709/core/account/account.dart';
import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:all_flutter0709/features/conversation/data/chat_local_data_source.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_summary.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
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
  static const _imageUploadUrl = 'https://upload.qiniup.com';
  static const _qiniuTokenApi = '/api/qiniu/uploadtoken';
  static const _messagePullApi = '/api/message/pull';
  static const _messageSendApi = '/api/chat/send';
  static const _modifyUserApi = '/api/user/modifyarray';

  final ChatLocalDataSource _localDataSource;
  final Dio _dio;
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

  Future<void> syncPulledMessages(String userId) async {
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
      throw Exception(result.message.isEmpty ? '拉取消息失败' : result.message);
    }

    final messages = result.data ?? const <ConversationMessage>[];
    if (messages.isEmpty) {
      return;
    }
    await _localDataSource.insertMessages(userId, messages);
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
    try {
      await _uploadImageToQiniu(
        userId: account.userId,
        clientMessageId: message.clientMessageId,
        filePath: message.localFilePath,
        filename: message.filename,
      );
      await _localDataSource.updateUploadProgress(
        account.userId,
        message.clientMessageId,
        100,
      );
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
    if (json == null) {
      throw Exception('服务器返回为空');
    }

    final result = ApiResponse<void>.fromJson(json);
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '发送失败' : result.message);
    }
  }

  Future<void> _uploadImageToQiniu({
    required String userId,
    required String clientMessageId,
    required String filePath,
    required String filename,
  }) async {
    final token = await _fetchQiniuUploadToken();
    await _dio.post<Object?>(
      _imageUploadUrl,
      data: FormData.fromMap({
        'token': token,
        'key': filename,
        'file': await MultipartFile.fromFile(
          filePath,
          filename: path.basename(filePath),
          contentType: MediaType(
            'image',
            path.extension(filePath).replaceAll('.', '').ifEmpty('jpeg'),
          ),
        ),
      }),
      options: Options(contentType: 'multipart/form-data'),
      onSendProgress: (count, total) {
        if (total <= 0) {
          return;
        }
        final progress = ((count / total) * 95).round().clamp(1, 95);
        _localDataSource.updateUploadProgress(
          userId,
          clientMessageId,
          progress,
        );
      },
    );
  }

  Future<String> _fetchQiniuUploadToken() async {
    final response = await _dio.get<Map<String, dynamic>>(_qiniuTokenApi);
    final json = response.data;
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
      throw Exception(result.message.isEmpty ? '上传凭证获取失败' : result.message);
    }

    final token = result.data?['token']?.toString() ?? '';
    if (token.isEmpty) {
      throw Exception('上传凭证为空');
    }
    return token;
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

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
