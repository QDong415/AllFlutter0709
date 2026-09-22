import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// 聊天语音播放：同一时间只播一条，对齐 Android `AudioPlayManager`。
class ChatVoicePlayHelper {
  ChatVoicePlayHelper({AudioPlayer? audioPlayer, this.onUpdate})
    : _audioPlayer = audioPlayer ?? AudioPlayer();

  final AudioPlayer _audioPlayer;
  StreamSubscription<ProcessingState>? _stateSubscription;
  String? _playingMessageId;
  VoidCallback? _onCompleted;

  /// 播放状态变化时刷新界面。
  final VoidCallback? onUpdate;

  /// 当前正在播放的气泡 id。
  String? get playingMessageId => _playingMessageId;

  void _notify() {
    onUpdate?.call();
  }

  /// 切换播放：点同一条则停止，点另一条则改播。
  Future<void> toggle({
    required String messageId,
    String? filePath,
    String? audioUrl,
    VoidCallback? onCompleted,
  }) async {
    if (_playingMessageId == messageId) {
      await stop();
      return;
    }

    await stop(notify: false);
    _playingMessageId = messageId;
    _onCompleted = onCompleted;
    _notify();

    try {
      final localPath = filePath?.trim() ?? '';
      if (localPath.isNotEmpty && await File(localPath).exists()) {
        await _audioPlayer.setFilePath(localPath);
      } else {
        final url = audioUrl?.trim() ?? '';
        if (url.isEmpty) {
          await stop();
          return;
        }
        await _audioPlayer.setUrl(url);
      }

      await _stateSubscription?.cancel();
      _stateSubscription = _audioPlayer.processingStateStream
          .skip(1)
          .listen((state) {
            if (state != ProcessingState.completed) {
              return;
            }
            final completedId = _playingMessageId;
            unawaited(stop());
            if (completedId != null) {
              _onCompleted?.call();
            }
          });

      unawaited(_audioPlayer.play());
    } catch (_) {
      await stop();
      rethrow;
    }
  }

  /// 停止当前播放。
  Future<void> stop({bool notify = true}) async {
    _playingMessageId = null;
    await _stateSubscription?.cancel();
    _stateSubscription = null;
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    if (notify) {
      _notify();
    }
  }

  /// 释放播放器。
  Future<void> dispose() async {
    await stop();
    await _audioPlayer.dispose();
  }
}
