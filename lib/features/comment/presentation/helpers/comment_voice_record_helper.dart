import 'dart:async';
import 'dart:io';

import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_recording_overlay.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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

/// 语音录制结束结果：取消、太短、或可发送的本地文件。
class ChatVoiceStopResult {
  const ChatVoiceStopResult._({
    this.file,
    this.filename = '',
    this.durationSeconds = 0,
    this.tooShort = false,
    this.cancelled = false,
  });

  const ChatVoiceStopResult.cancelled() : this._(cancelled: true);

  const ChatVoiceStopResult.tooShort() : this._(tooShort: true);

  ChatVoiceStopResult.success({
    required File file,
    required String filename,
    required int durationSeconds,
  }) : this._(file: file, filename: filename, durationSeconds: durationSeconds);

  final File? file;
  final String filename;
  final int durationSeconds;
  final bool tooShort;
  final bool cancelled;

  bool get canSend =>
      !cancelled && !tooShort && file != null && filename.isNotEmpty;
}

/// 评论按住说话：交互对齐聊天，松手仅保存草稿，需点「发送」提交。
class CommentVoiceRecordHelper {
  CommentVoiceRecordHelper({
    AudioRecorder? audioRecorder,
    required this.onUpdate,
    required this.onRecorded,
    required this.onTip,
    this.onHidePanel,
    this.isBusy,
  }) : _audioRecorder = audioRecorder ?? AudioRecorder();

  /// 遮罩 / 取消态变化时刷新界面。
  final VoidCallback onUpdate;

  /// 录音成功结束，回填待发送语音。
  final void Function(File file, int seconds) onRecorded;

  /// 权限失败、录音过短等轻提示。
  final ValueChanged<String> onTip;

  /// 开始录音后收起键盘与面板。
  final VoidCallback? onHidePanel;

  /// 发送中等忙碌态，按下时忽略。
  final bool Function()? isBusy;

  final AudioRecorder _audioRecorder;
  Timer? _recordTimer;
  Timer? _maxDurationTimer;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Stopwatch? _stopwatch;
  String? _filePath;
  String? _filename;
  bool _engineRunning = false;

  bool _pointerDown = false;
  int _session = 0;
  Offset? _pointerStart;
  bool _showOverlay = false;
  bool _willCancel = false;
  int _durationSeconds = 0;
  double _amplitude = _idleAmplitude;

  static const _idleAmplitude = -45.0;
  static const _maxDurationSeconds = 60;
  static const _minDurationMilliseconds = 1000;

  /// 是否正在展示录音遮罩。
  bool get isRecording => _showOverlay;

  /// 手指是否滑到取消发送区。
  bool get willCancel => _willCancel;

  /// 当前已录秒数。
  int get durationSeconds => _durationSeconds;

  /// 当前振幅（dBFS）。
  double get amplitude => _amplitude;

  /// 手指按下：申请权限并开始录音。
  Future<void> handlePointerDown(Offset globalPosition) async {
    if (isBusy?.call() == true || _pointerDown) {
      return;
    }

    _pointerDown = true;
    _pointerStart = globalPosition;
    _willCancel = false;
    final session = ++_session;

    final result = await start();
    if (session != _session) {
      if (result.isSuccess) {
        await stop(cancel: true);
      }
      return;
    }

    if (!result.isSuccess) {
      _pointerDown = false;
      onTip(result.errorMessage!);
      return;
    }

    _showOverlay = true;
    _willCancel = false;
    _durationSeconds = 0;
    _amplitude = _idleAmplitude;
    onUpdate();
    onHidePanel?.call();

    if (!_pointerDown || session != _session) {
      await finish(cancel: _willCancel);
    }
  }

  /// 手指移动：上滑超过阈值进入取消态。
  void handlePointerMove(Offset globalPosition) {
    if (!_pointerDown) {
      return;
    }
    final start = _pointerStart;
    if (start == null) {
      return;
    }
    final shouldCancel = globalPosition.dy - start.dy < -60;
    if (shouldCancel == _willCancel) {
      return;
    }
    _willCancel = shouldCancel;
    onUpdate();
  }

  /// 手指抬起：按取消态结束录音。
  void handlePointerUp() {
    if (!_pointerDown) {
      return;
    }
    _pointerDown = false;
    unawaited(finish(cancel: _willCancel));
  }

  /// 手势取消：丢弃当前录音。
  void handlePointerCancel() {
    if (!_pointerDown && !_showOverlay) {
      return;
    }
    _pointerDown = false;
    _session++;
    unawaited(finish(cancel: true));
  }

  /// 结束本轮按住说话并按结果发送或丢弃。
  Future<void> finish({required bool cancel}) async {
    final hadOverlay = _showOverlay;
    if (!hadOverlay && !_engineRunning) {
      return;
    }
    if (hadOverlay) {
      _showOverlay = false;
      _willCancel = false;
      _amplitude = _idleAmplitude;
      _durationSeconds = 0;
      onUpdate();
    }

    final result = await stop(cancel: cancel);
    if (!hadOverlay) {
      return;
    }
    if (cancel || result.cancelled) {
      return;
    }
    if (result.tooShort) {
      onTip('录音时间太短');
      return;
    }
    if (!result.canSend) {
      return;
    }
    final file = result.file;
    if (file != null) {
      onRecorded(file, result.durationSeconds);
    }
  }

  /// 录音遮罩；未录音时返回 null。
  Widget? buildOverlay() {
    if (!_showOverlay) {
      return null;
    }
    return Positioned.fill(
      child: IgnorePointer(
        child: ChatRecordingOverlay(
          isCancelling: _willCancel,
          seconds: _durationSeconds <= 0 ? 1 : _durationSeconds,
          amplitude: _amplitude,
        ),
      ),
    );
  }

  /// 开始录音；达到 60 秒时自动结束并回调 [onRecorded]。
  Future<ChatVoiceStartResult> start() async {
    if (_engineRunning) {
      return const ChatVoiceStartResult.failure('正在录音');
    }

    final permissionStatus = await Permission.microphone.request();
    if (!permissionStatus.isGranted) {
      return ChatVoiceStartResult.failure(
        permissionStatus.isPermanentlyDenied ? '请在系统设置中开启麦克风权限' : '需要麦克风权限才能录音',
      );
    }

    final directory = await getTemporaryDirectory();
    final filename = 'comment-${DateTime.now().millisecondsSinceEpoch}.m4a';
    final path = '${directory.path}${Platform.pathSeparator}$filename';

    try {
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          numChannels: 1,
          bitRate: 96000,
          sampleRate: 44100,
        ),
        path: path,
      );
      _filename = filename;
      _filePath = path;
    } catch (_) {
      return const ChatVoiceStartResult.failure('录音启动失败');
    }

    _engineRunning = true;
    _stopwatch = Stopwatch()..start();
    _listenAmplitude();
    _startTimers();
    return const ChatVoiceStartResult.success();
  }

  void _listenAmplitude() {
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 80))
        .listen((amplitude) {
          _amplitude = amplitude.current;
          onUpdate();
        });
  }

  void _startTimers() {
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_showOverlay) {
        return;
      }
      _durationSeconds++;
      onUpdate();
    });
    _maxDurationTimer?.cancel();
    _maxDurationTimer = Timer(const Duration(seconds: _maxDurationSeconds), () {
      _pointerDown = false;
      unawaited(finish(cancel: false));
    });
  }

  /// 结束录音；[cancel] 为 true 时丢弃文件。
  Future<ChatVoiceStopResult> stop({required bool cancel}) async {
    if (!_engineRunning) {
      return const ChatVoiceStopResult.cancelled();
    }

    _engineRunning = false;
    _recordTimer?.cancel();
    _recordTimer = null;
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;

    final elapsed = _stopwatch?.elapsed ?? Duration.zero;
    _stopwatch?.stop();
    _stopwatch = null;

    final filename = _filename ?? '';
    final filePath = _filePath;
    _filename = null;
    _filePath = null;

    if (cancel) {
      await _audioRecorder.cancel();
      await _deleteFile(filePath);
      return const ChatVoiceStopResult.cancelled();
    }

    final stoppedPath = await _audioRecorder.stop();
    final resolvedPath = stoppedPath ?? filePath;
    if (resolvedPath == null || resolvedPath.isEmpty) {
      return const ChatVoiceStopResult.cancelled();
    }

    if (elapsed.inMilliseconds < _minDurationMilliseconds) {
      await _deleteFile(resolvedPath);
      return const ChatVoiceStopResult.tooShort();
    }

    final file = File(resolvedPath);
    if (!await file.exists()) {
      return const ChatVoiceStopResult.cancelled();
    }

    final durationSeconds = elapsed.inSeconds.clamp(1, _maxDurationSeconds);
    return ChatVoiceStopResult.success(
      file: file,
      filename: filename.isEmpty ? file.uri.pathSegments.last : filename,
      durationSeconds: durationSeconds,
    );
  }

  /// 释放录音器与订阅。
  Future<void> dispose() async {
    if (_engineRunning || _showOverlay) {
      await finish(cancel: true);
    }
    _recordTimer?.cancel();
    _recordTimer = null;
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    await _audioRecorder.dispose();
  }

  Future<void> _deleteFile(String? path) async {
    if (path == null || path.isEmpty) {
      return;
    }
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
