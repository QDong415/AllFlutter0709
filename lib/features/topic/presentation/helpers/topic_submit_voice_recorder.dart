import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// 发布页按住录音。最长 60 秒，短于 1 秒丢弃。
class TopicSubmitVoiceRecorder {
  TopicSubmitVoiceRecorder({this.onTick, this.onAmplitude, this.onAutoStop});

  /// 录音秒数变化。
  final VoidCallback? onTick;

  /// 麦克风音量采样变化。
  final VoidCallback? onAmplitude;

  /// 到达 60 秒时自动结束，带回文件和秒数。
  final void Function(File file, int seconds)? onAutoStop;

  final AudioRecorder _recorder = AudioRecorder();
  Timer? _timer;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Stopwatch? _watch;
  String? _path;
  bool _recording = false;
  int _seconds = 0;
  int _session = 0;
  double _amplitude = _idleAmplitude;

  static const double _idleAmplitude = -45.0;

  /// 是否正在录音。
  bool get isRecording => _recording;

  /// 当前已录秒数。
  int get seconds => _seconds;

  /// 当前音量（dBFS），用于音浪 UI。
  double get amplitude => _amplitude;

  /// 开始录音。失败时返回提示文案。
  Future<String?> start() async {
    if (_recording) {
      return '正在录音';
    }
    final session = ++_session;
    final permissionStatus = await Permission.microphone.request();
    if (session != _session) {
      return null;
    }
    if (!permissionStatus.isGranted) {
      return permissionStatus.isPermanentlyDenied
          ? '请在系统设置中开启麦克风权限'
          : '需要麦克风权限才能录音';
    }
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}${Platform.pathSeparator}topic-${DateTime.now().millisecondsSinceEpoch}.m4a';
    try {
      if (session != _session) {
        return null;
      }
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          numChannels: 1,
          bitRate: 96000,
          sampleRate: 44100,
        ),
        path: path,
      );
    } catch (_) {
      return '录音启动失败';
    }
    if (session != _session) {
      await _recorder.cancel();
      await _delete(path);
      return null;
    }
    _path = path;
    _recording = true;
    _seconds = 0;
    _amplitude = _idleAmplitude;
    _listenAmplitude();
    _watch = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _seconds++;
      onTick?.call();
      if (_seconds >= 60) {
        unawaited(_finishAtMax());
      }
    });
    return null;
  }

  /// 松手结束。太短或失败时返回 null，并带回提示。
  Future<({File? file, int seconds, String? message})> stop() async {
    if (!_recording) {
      _session++;
      return (file: null, seconds: 0, message: null);
    }
    final elapsed = _watch?.elapsed ?? Duration.zero;
    final path = await _end();
    if (elapsed.inMilliseconds < 1000) {
      await _delete(path);
      return (file: null, seconds: 0, message: '录音太短');
    }
    if (path == null) {
      return (file: null, seconds: 0, message: '录音失败');
    }
    final file = File(path);
    if (!await file.exists() || await file.length() <= 0) {
      return (file: null, seconds: 0, message: '录音失败');
    }
    final seconds = elapsed.inSeconds.clamp(1, 60);
    return (file: file, seconds: seconds, message: null);
  }

  /// 取消并删除文件。
  Future<void> cancel() async {
    if (!_recording) {
      _session++;
      return;
    }
    final path = await _end(cancelRecorder: true);
    await _delete(path);
  }

  /// 释放录音器。
  Future<void> dispose() async {
    await cancel();
    await _recorder.dispose();
  }

  Future<void> _finishAtMax() async {
    final result = await stop();
    final file = result.file;
    if (file != null) {
      onAutoStop?.call(file, result.seconds);
    }
  }

  void _listenAmplitude() {
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 80))
        .listen((sample) {
          _amplitude = sample.current;
          onAmplitude?.call();
        });
  }

  Future<String?> _end({bool cancelRecorder = false}) async {
    _recording = false;
    _timer?.cancel();
    _timer = null;
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    _amplitude = _idleAmplitude;
    _watch?.stop();
    _watch = null;
    final path = _path;
    _path = null;
    try {
      if (cancelRecorder) {
        await _recorder.cancel();
      } else {
        final stopped = await _recorder.stop();
        return stopped ?? path;
      }
    } catch (_) {}
    return path;
  }

  Future<void> _delete(String? path) async {
    if (path == null || path.isEmpty) {
      return;
    }
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
