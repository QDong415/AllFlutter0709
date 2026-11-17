import 'dart:async';

/// 应用内音频播放协调器：聊天语音、动态语音等同一时间只允许一路发声。
class AppAudioPlaybackCoordinator {
  AppAudioPlaybackCoordinator._();

  /// 全局协调器。
  static final AppAudioPlaybackCoordinator instance =
      AppAudioPlaybackCoordinator._();

  Object? _owner;
  Future<void> Function()? _stopCurrent;
  Future<void> _operation = Future<void>.value();

  /// 停掉上一播放方并执行 [start]，把音频所有权交给 [owner]。
  Future<void> start({
    required Object owner,
    required Future<void> Function() stop,
    required FutureOr<void> Function() start,
  }) {
    final completer = Completer<void>();
    _operation = _operation
        .then((_) async {
          if (!identical(_owner, owner)) {
            final stopPrevious = _stopCurrent;
            _owner = null;
            _stopCurrent = null;
            if (stopPrevious != null) {
              try {
                await stopPrevious();
              } catch (_) {}
            }
          }
          _owner = owner;
          _stopCurrent = stop;
          await start();
          completer.complete();
        })
        .catchError((Object error, StackTrace stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        });
    return completer.future;
  }

  /// [owner] 主动暂停、停止或播放完成后释放所有权。
  void release(Object owner) {
    if (!identical(_owner, owner)) {
      return;
    }
    _owner = null;
    _stopCurrent = null;
  }
}
