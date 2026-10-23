import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:all_flutter0709/core/push/chat_push_log.dart';
import 'package:all_flutter0709/features/conversation/data/chat_local_data_source.dart';
import 'package:all_flutter0709/features/conversation/data/chat_voice_service.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';

/// 聊天消息同步服务：拉取远端消息、落库并补齐语音文件。
class ChatMessageSyncService {
  const ChatMessageSyncService({
    required ChatLocalDataSource localDataSource,
    required ChatVoiceService voiceService,
  }) : _localDataSource = localDataSource,
       _voiceService = voiceService;

  static const _messagePullApi = '/api/message/pull';

  final ChatLocalDataSource _localDataSource;
  final ChatVoiceService _voiceService;

  /// 拉取并保存当前用户的新消息，返回新增或更新数量。
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

    final messageList = result.data ?? const <ConversationMessage>[];
    ChatPushLog.d('message/pull 返回 ${messageList.length} 条');
    if (messageList.isEmpty) {
      return 0;
    }
    final inserted = await _localDataSource.insertMessages(userId, messageList);
    ChatPushLog.d('message/pull 处理 $inserted 条（新写入或撤回更新）');
    await _voiceService.ensureLocalFiles(userId, messageList);
    return inserted;
  }
}
