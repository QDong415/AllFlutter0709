import 'dart:convert';
import 'dart:io';

import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:path_provider/path_provider.dart';

/// MiniMax 拒绝了这句正文。气泡保持原样，喇叭回到静止。
class ChatAiSpeechRejected implements Exception {
  const ChatAiSpeechRejected();
}

/// 把 AI 文字气泡合成 mp3，并按消息 id 缓存在沙盒。
///
/// 进行中的合成挂在本类的静态表上，不跟某一个聊天页走。
/// 页面关掉后请求仍会写完文件；再次进入后点同一条，会等到这一次的结果。
class ChatAiSpeechHelper {
  const ChatAiSpeechHelper();

  static const _api = '/api/chat/speech';
  static const _cacheVersion = 'v3';

  /// 同一条消息同时只合成一次。完成后从表里拿掉，失败可以再点。
  static final Map<int, Future<String>> _inFlight = {};

  /// 沙盒里已经有这条消息的 mp3 时返回路径。
  Future<String?> cachedPath(int msgId) {
    if (msgId <= 0) {
      return Future<String?>.value();
    }
    return _findCached(msgId);
  }

  /// 已缓存则直接返回路径，否则请求接口并写入沙盒。
  Future<String> ensureFile(int msgId) async {
    if (msgId <= 0) {
      throw Exception('这条还没同步好');
    }
    final cached = await _findCached(msgId);
    if (cached != null) {
      return cached;
    }
    return _joinInFlight(msgId);
  }

  /// 已经有同 msgid 的请求就跟着等，否则发起一次并记到 [_inFlight]。
  Future<String> _joinInFlight(int msgId) {
    final existing = _inFlight[msgId];
    if (existing != null) {
      return existing;
    }
    late final Future<String> future;
    future = _download(msgId).whenComplete(() {
      if (identical(_inFlight[msgId], future)) {
        _inFlight.remove(msgId);
      }
    });
    _inFlight[msgId] = future;
    return future;
  }

  Future<String> _download(int msgId) async {
    final response = await HttpClient.instance.post(
      _api,
      data: <String, Object?>{'msgid': msgId},
      receiveTimeout: const Duration(seconds: 60),
    );
    final json = response.data;
    if (json == null) {
      throw Exception('语音合成失败');
    }
    final code = (json['code'] as num?)?.toInt() ?? 0;
    if (code == 1026 || code == 1027) {
      throw const ChatAiSpeechRejected();
    }
    final result = ApiResponse<Map<String, dynamic>>.fromJson(json, (dataJson) {
      if (dataJson is Map<String, dynamic>) {
        return dataJson;
      }
      if (dataJson is Map) {
        return dataJson.map((key, value) => MapEntry(key.toString(), value));
      }
      return const <String, dynamic>{};
    });
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '语音合成失败' : result.message);
    }
    final audio = result.data?['audio']?.toString() ?? '';
    final voiceId = result.data?['voice_id']?.toString() ?? '';
    if (audio.isEmpty) {
      throw Exception('语音合成失败');
    }
    final bytes = base64Decode(audio);
    final file = File(await _filePath(msgId, voiceId));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<String?> _findCached(int msgId) async {
    final dir = Directory(await _dirPath());
    if (!await dir.exists()) {
      return null;
    }
    final prefix = '${msgId}_';
    final suffix = '_$_cacheVersion.mp3';
    await for (final entity in dir.list()) {
      if (entity is! File) {
        continue;
      }
      final name = entity.uri.pathSegments.last;
      final matched = name.startsWith(prefix) && name.endsWith(suffix);
      if (matched) {
        return entity.path;
      }
    }
    return null;
  }

  Future<String> _filePath(int msgId, String voiceId) async {
    final safeVoice = voiceId.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    final name = safeVoice.isEmpty
        ? '${msgId}_$_cacheVersion.mp3'
        : '${msgId}_${safeVoice}_$_cacheVersion.mp3';
    return '${await _dirPath()}/$name';
  }

  Future<String> _dirPath() async {
    final root = await getApplicationDocumentsDirectory();
    return '${root.path}/ai_speech';
  }
}
