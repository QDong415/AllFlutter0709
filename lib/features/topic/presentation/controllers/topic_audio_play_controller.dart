import 'dart:async';
import 'dart:io';

import 'package:all_flutter0709/core/audio/app_audio_playback_coordinator.dart';
import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:all_flutter0709/features/topic/data/topic_audio_file_store.dart';
import 'package:all_flutter0709/features/topic/data/topic_audio_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:just_audio/just_audio.dart';

/// 语音条所处阶段。同一时间只有一条处于 loading / playing / paused。
enum TopicAudioPhase { idle, loading, playing, paused }

/// 动态语音播放：点击才播，同时只一条。
///
/// 下载任务按 tid 保留。切到另一条或滑出屏幕只取消播放意图，下载完成后不自动播。
class TopicAudioPlayController extends ChangeNotifier
    with WidgetsBindingObserver {
  TopicAudioPlayController() {
    WidgetsBinding.instance.addObserver(this);
    _positionSubscription = _player.positionStream.listen(_onPosition);
    _stateSubscription = _player.playerStateStream.listen(_onPlayerState);
  }

  final AudioPlayer _player = AudioPlayer();
  final Object _playbackOwner = Object();
  final Map<String, Future<File?>> _downloadMap = <String, Future<File?>>{};

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;

  String? _playKey;
  TopicAudioPhase _phase = TopicAudioPhase.idle;
  double _progress = 0;
  int _positionSeconds = 0;
  int _durationSeconds = 0;
  int _generation = 0;
  String _errorText = '';
  int _errorNonce = 0;

  /// 当前想播放的标识（动态 tid 或评论 `c:cid`）。为空表示没有播放意图。
  String? get targetPlayKey => _playKey;

  /// 兼容旧调用。
  String? get targetTid => _playKey;

  /// 当前阶段。只有 [targetPlayKey] 对应的语音条会显示 loading / 进度。
  TopicAudioPhase get phase => _phase;

  /// 当前目标的播放进度，0 到 1。
  double get progress => _progress;

  /// 当前目标已播放秒数。空闲时为 0。
  int get positionSeconds => _positionSeconds;

  /// 当前目标的总时长，秒。
  int get durationSeconds => _durationSeconds;

  /// 最近一次失败文案。
  String get errorText => _errorText;

  /// 失败次数。界面用来决定是否弹出提示。
  int get errorNonce => _errorNonce;

  /// 点击动态语音条。
  Future<void> onTap(TopicModel topicModel) async {
    await onTapSource(TopicAudioSource.fromTopic(topicModel));
  }

  /// 点击语音条。同一条在播则暂停，暂停后再点继续；点另一条会停掉当前这条。
  Future<void> onTapSource(TopicAudioSource source) async {
    final key = source.playKey.trim();
    if (key.isEmpty || !source.canPlay) {
      return;
    }
    if (_playKey == key && _phase == TopicAudioPhase.playing) {
      await _pause();
      return;
    }
    if (_playKey == key && _phase == TopicAudioPhase.paused) {
      await _resume();
      return;
    }
    if (_playKey == key && _phase == TopicAudioPhase.loading) {
      _dropIntent();
      return;
    }

    final generation = ++_generation;
    // 先同步冻结 UI，再停止和重新装载播放器。just_audio 在 stop/setFilePath
    // 完成前仍可能发出上一轮 position；idle 阶段会忽略这些事件，避免进度
    // 先前进约 0.2 秒、随后又回到 0。
    _playKey = key;
    _phase = TopicAudioPhase.idle;
    _durationSeconds = source.audioDurationSeconds;
    _positionSeconds = 0;
    _progress = 0;
    notifyListeners();

    await _stopPlayer();
    if (generation != _generation) {
      return;
    }

    File? readyFile;
    final pending = source.localFile;
    if (pending != null &&
        await pending.exists() &&
        await pending.length() > 0) {
      readyFile = pending;
    } else if (source.hasRemoteAudio) {
      readyFile = await TopicAudioFileStore.cachedFileForName(
        source.audioFileName,
      );
    }
    if (readyFile == null) {
      _phase = TopicAudioPhase.loading;
      notifyListeners();
    }

    final file = readyFile ?? await _localOrDownload(source);
    if (generation != _generation || _playKey != key) {
      return;
    }
    if (file == null) {
      _dropIntent();
      _fail('语音下载失败');
      return;
    }
    await _startFile(file, generation, key);
  }

  /// 整格滑出屏幕、被盖住或退到后台时调用。下载继续，但完成后不自动播。
  void onHidden(String playKey) {
    if (_playKey != playKey.trim()) {
      return;
    }
    _dropIntent();
  }

  /// 离开承载页（如 pop 动态详情）时停止当前播放，不限 playKey。
  void stopCurrentPlayback() {
    if (_playKey == null) {
      return;
    }
    _dropIntent();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      final key = _playKey;
      if (key != null) {
        onHidden(key);
      }
    }
  }

  @override
  void dispose() {
    AppAudioPlaybackCoordinator.instance.release(_playbackOwner);
    WidgetsBinding.instance.removeObserver(this);
    _positionSubscription?.cancel();
    _stateSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<File?> _localOrDownload(TopicAudioSource source) async {
    final localFile = await TopicAudioFileStore.fileForName(
      source.audioFileName,
    );
    final inflight = _downloadMap[source.playKey];
    if (inflight != null) {
      return inflight;
    }
    final future = _download(source, localFile);
    _downloadMap[source.playKey] = future;
    future.whenComplete(() => _downloadMap.remove(source.playKey));
    return future;
  }

  Future<File?> _download(TopicAudioSource source, File localFile) async {
    final url = source.audioUrl.trim();
    if (url.isEmpty) {
      return null;
    }
    try {
      final downloader = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 60),
          followRedirects: true,
        ),
      );
      await downloader.download(url, localFile.path);
      if (await localFile.exists() && await localFile.length() > 0) {
        return localFile;
      }
    } catch (_) {
      if (await localFile.exists()) {
        await localFile.delete();
      }
    }
    return null;
  }

  Future<void> _startFile(File file, int generation, String playKey) async {
    try {
      await _player.setFilePath(file.path);
      if (generation != _generation || _playKey != playKey) {
        return;
      }
      await AppAudioPlaybackCoordinator.instance.start(
        owner: _playbackOwner,
        stop: _stopForCoordinator,
        start: () {
          if (generation != _generation || _playKey != playKey) {
            return;
          }
          _phase = TopicAudioPhase.playing;
          _positionSeconds = 0;
          _progress = 0;
          notifyListeners();
          unawaited(_player.play());
        },
      );
    } catch (_) {
      if (generation != _generation || _playKey != playKey) {
        return;
      }
      _dropIntent();
      _fail('语音播放失败');
    }
  }

  Future<void> _pause() async {
    AppAudioPlaybackCoordinator.instance.release(_playbackOwner);
    _phase = TopicAudioPhase.paused;
    notifyListeners();
    try {
      await _player.pause();
    } catch (_) {}
  }

  Future<void> _resume() async {
    try {
      await AppAudioPlaybackCoordinator.instance.start(
        owner: _playbackOwner,
        stop: _stopForCoordinator,
        start: () {
          _phase = TopicAudioPhase.playing;
          notifyListeners();
          unawaited(_player.play());
        },
      );
    } catch (_) {
      _dropIntent();
      _fail('语音播放失败');
    }
  }

  void _dropIntent() {
    _generation++;
    AppAudioPlaybackCoordinator.instance.release(_playbackOwner);
    _playKey = null;
    _phase = TopicAudioPhase.idle;
    _progress = 0;
    _positionSeconds = 0;
    notifyListeners();
    try {
      unawaited(_player.pause());
    } catch (_) {}
    unawaited(_stopPlayer());
  }

  Future<void> _stopForCoordinator() async {
    _generation++;
    _playKey = null;
    _phase = TopicAudioPhase.idle;
    _progress = 0;
    _positionSeconds = 0;
    notifyListeners();
    await _stopPlayer();
  }

  Future<void> _stopPlayer() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  void _onPosition(Duration position) {
    if (_phase != TopicAudioPhase.playing && _phase != TopicAudioPhase.paused) {
      return;
    }
    // 新开播且 UI 仍在 0 时，丢弃上一轮残留的 position（常见约 0.2 秒）。
    if (_phase == TopicAudioPhase.playing &&
        _progress == 0 &&
        _positionSeconds == 0 &&
        position.inMilliseconds > 500) {
      return;
    }
    final total =
        _player.duration ??
        Duration(seconds: _durationSeconds > 0 ? _durationSeconds : 0);
    final totalMs = total.inMilliseconds;
    _positionSeconds = position.inSeconds;
    _progress = totalMs <= 0
        ? 0
        : (position.inMilliseconds / totalMs).clamp(0.0, 1.0);
    notifyListeners();
  }

  void _onPlayerState(PlayerState state) {
    if (state.processingState != ProcessingState.completed) {
      return;
    }
    if (_phase != TopicAudioPhase.playing) {
      return;
    }
    _generation++;
    AppAudioPlaybackCoordinator.instance.release(_playbackOwner);
    _playKey = null;
    _phase = TopicAudioPhase.idle;
    _progress = 0;
    _positionSeconds = 0;
    notifyListeners();
  }

  void _fail(String message) {
    _errorText = message;
    _errorNonce++;
    notifyListeners();
  }
}

/// 全局唯一的动态语音播放器。
final topicAudioPlayControllerProvider =
    ChangeNotifierProvider<TopicAudioPlayController>((ref) {
      return TopicAudioPlayController();
    });