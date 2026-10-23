import 'dart:io';

import 'package:all_flutter0709/core/push/chat_push_log.dart';
import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:all_flutter0709/features/conversation/data/chat_local_data_source.dart';
import 'package:all_flutter0709/features/conversation/data/chat_voice_file_store.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';
import 'package:dio/dio.dart';

/// 聊天语音本地服务：下载语音文件并维护播放状态。
class ChatVoiceService {
  const ChatVoiceService({required ChatLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  final ChatLocalDataSource _localDataSource;

  /// 确保消息中的语音已经下载到本地。
  Future<void> ensureLocalFiles(
    String userId,
    List<ConversationMessage> messageList,
  ) async {
    for (final messageModel in messageList) {
      if (messageModel.messageType != ConversationMessageType.voice) {
        continue;
      }
      final filename = messageModel.filename.trim();
      if (filename.isEmpty) {
        continue;
      }

      final localPath = await ChatVoiceFileStore.pathForFileName(filename);
      final localFile = File(localPath);
      if (await localFile.exists()) {
        if (messageModel.localFilePath != localPath) {
          await _localDataSource.updateLocalFilePath(
            userId: userId,
            localFilePath: localPath,
            msgId: messageModel.msgId,
            clientMessageId: messageModel.clientMessageId,
          );
        }
        continue;
      }

      final url = ValueUtil.getQiniuUrlByFileName(filename, keepOriginal: true);
      if (url == null || url.isEmpty) {
        continue;
      }

      try {
        ChatSendLog.d('下载语音 msgid=${messageModel.msgId} url=$url');
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
          msgId: messageModel.msgId,
          clientMessageId: messageModel.clientMessageId,
        );
        ChatSendLog.d('语音下载完成 msgid=${messageModel.msgId} path=$localPath');
      } catch (error) {
        ChatSendLog.d('语音下载失败 msgid=${messageModel.msgId}: $error');
        if (!messageModel.isSender && messageModel.msgId > 0) {
          await _localDataSource.updateMessageStatusByMsgId(
            userId,
            messageModel.msgId,
            ConversationMessageStatus.failed,
          );
        }
      }
    }
  }

  /// 将收到的语音标记为已播放。
  Future<void> markPlayed({
    required String userId,
    required int msgId,
    required int durationSeconds,
  }) {
    if (msgId <= 0) {
      return Future<void>.value();
    }
    return _localDataSource.updateMessageExtend(
      userId: userId,
      msgId: msgId,
      extend: ConversationMessage.voiceExtendJson(
        durationSeconds: durationSeconds,
        hadPlay: true,
      ),
    );
  }
}
