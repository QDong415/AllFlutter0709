import 'package:all_flutter0709/core/bridge/native_methods.dart';
import 'package:flutter/services.dart';

/// Channel 单例：业务侧不要直接 new MethodChannel / EventChannel。
class NativeChannel {
  NativeChannel._();

  static final NativeChannel instance = NativeChannel._();

  /// 主通道（请求 / 同步结果 / Native invokeMethod）。
  final MethodChannel method = const MethodChannel(NativeChannels.bridge);

  /// 事件流通道（Native → Flutter 订阅语义）。
  final EventChannel events = const EventChannel(NativeChannels.events);
}
