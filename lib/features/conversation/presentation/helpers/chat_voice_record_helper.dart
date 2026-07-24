import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// 语音录制开始结果：成功或带错误文案失败。
class ChatVoiceStartResult {
  const ChatVoiceStartResult._({this.errorMessage});

  const ChatVoiceStartResult.success() : this._();

  const ChatVoiceStartResult.failure(String message)
    : this._(errorMessage: message);

  final String? errorMessage;

  bool get isSuccess => errorMessage == null;
}

/// 聊天语音录制：权限、起停、时长与振幅监听。
class ChatVoiceRecordHelper {
  ChatVoiceRecordHelper({AudioRecorder? audioRecorder})
    : _audioRecorder = audioRecorder ?? AudioRecorder();

  final AudioRecorder _audioRecorder;
  Timer? _recordTimer;
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  /// 开始录音；[onAmplitude] / [onTick] 由页面驱动 UI。
  Future<ChatVoiceStartResult> start({
    required void Function(double amplitude) onAmplitude,
    required VoidCallback onTick,
  }) async {
    final permissionStatus = await Permission.microphone.request();
    if (!permissionStatus.isGranted) {
      return ChatVoiceStartResult.failure(
        permissionStatus.isPermanentlyDenied
            ? '请在系统设置中开启麦克风权限'
            : '需要麦克风权限才能录音',
      );
    }

    final path =
        '${Directory.systemTemp.path}'
        '${Platform.pathSeparator}'
        'chat_record_${DateTime.now().millisecondsSinceEpoch}.m4a';

    try {
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          numChannels: 1,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );
    } catch (_) {
      return const ChatVoiceStartResult.failure('录音启动失败');
    }

    _recordTimer?.cancel();
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 180))
        .listen((amplitude) {
          onAmplitude(amplitude.current);
        });

    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      onTick();
    });

    return const ChatVoiceStartResult.success();
  }

  /// 根据手指上滑距离判断是否进入取消态。
  bool shouldCancelFromMove(LongPressMoveUpdateDetails details) {
    return details.offsetFromOrigin.dy < -60;
  }

  /// 结束录音；[cancel] 为 true 时丢弃，否则 stop。
  Future<void> stop({required bool cancel}) async {
    _recordTimer?.cancel();
    _recordTimer = null;
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;

    if (cancel) {
      await _audioRecorder.cancel();
      return;
    }

    await _audioRecorder.stop();
  }

  /// 释放录音器与订阅。
  Future<void> dispose() async {
    _recordTimer?.cancel();
    _recordTimer = null;
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    await _audioRecorder.dispose();
  }
}
