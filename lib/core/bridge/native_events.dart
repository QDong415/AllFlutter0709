import 'dart:async';

import 'package:all_flutter0709/core/bridge/native_channel.dart';
import 'package:all_flutter0709/core/bridge/native_event_model.dart';
import 'package:all_flutter0709/core/bridge/native_methods.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native → Flutter 事件入口：MethodChannel.emit + EventChannel 订阅流。
class NativeEvents {
  NativeEvents._();

  static final NativeEvents instance = NativeEvents._();

  static const _sourceMethod = 'method';
  static const _sourceEventChannel = 'eventChannel';

  final MethodChannel _methodChannel = NativeChannel.instance.method;
  final EventChannel _eventChannel = NativeChannel.instance.events;

  final StreamController<NativeEventModel> _methodEmitController =
      StreamController<NativeEventModel>.broadcast();

  StreamSubscription<dynamic>? _eventChannelSubscription;
  bool _started = false;

  /// MethodChannel `emit` 推过来的事件流。
  Stream<NativeEventModel> get methodEmits => _methodEmitController.stream;

  /// EventChannel 订阅流（与 methodEmits 并行，便于对比两种通道）。
  final StreamController<NativeEventModel> _eventChannelController =
      StreamController<NativeEventModel>.broadcast();

  /// EventChannel 解析后的事件流。
  Stream<NativeEventModel> get eventChannelEvents =>
      _eventChannelController.stream;

  /// 合并后的事件流（调试面板可只听这一个）。
  Stream<NativeEventModel> get allEvents => Stream<NativeEventModel>.multi((
    multi,
  ) {
    final subs = <StreamSubscription<NativeEventModel>>[
      methodEmits.listen(multi.add),
      eventChannelEvents.listen(multi.add),
    ];
    multi.onCancel = () async {
      for (final sub in subs) {
        await sub.cancel();
      }
    };
  });

  /// 注册 MethodCallHandler 并开始监听 EventChannel；可重复调用，只生效一次。
  void start() {
    if (_started) {
      return;
    }
    _started = true;

    _methodChannel.setMethodCallHandler(_onMethodCall);

    _eventChannelSubscription = _eventChannel
        .receiveBroadcastStream()
        .listen(
          (dynamic raw) {
            final event = NativeEventModel.tryParse(
              raw,
              source: _sourceEventChannel,
            );
            if (event != null) {
              _eventChannelController.add(event);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('[NativeEvents] EventChannel error: $error\n$stackTrace');
          },
        );
  }

  /// 停止监听（一般仅测试需要）。
  Future<void> stop() async {
    if (!_started) {
      return;
    }
    _started = false;
    _methodChannel.setMethodCallHandler(null);
    await _eventChannelSubscription?.cancel();
    _eventChannelSubscription = null;
  }

  Future<dynamic> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case NativeMethods.emit:
        final event = NativeEventModel.tryParse(
          call.arguments,
          source: _sourceMethod,
        );
        if (event != null) {
          _methodEmitController.add(event);
        }
        return null;
      default:
        debugPrint('[NativeEvents] 未处理 method: ${call.method}');
        throw MissingPluginException(
          'No handler for method ${call.method} on ${NativeChannels.bridge}',
        );
    }
  }
}
