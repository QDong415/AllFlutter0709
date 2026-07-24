/// 原生 Bridge 通道名与 method / api / event 常量（双端必须对齐）。
abstract final class NativeChannels {
  /// 主 MethodChannel：双向指令与同步 Result。
  static const bridge = 'com.dq.allflutter0709/bridge';

  /// EventChannel：Native → Flutter 可订阅事件流（适合持续推送）。
  static const events = 'com.dq.allflutter0709/events';
}

/// MethodChannel 上的 method 名分区。
abstract final class NativeMethods {
  /// Flutter → Native：通用能力调用。
  static const call = 'call';

  /// Native → Flutter：低频事件推送（走 MethodChannel）。
  static const emit = 'emit';
}

/// [NativeMethods.call] 的 `api` 字段取值。
abstract final class NativeApis {
  /// 连通性探测，期望返回 `"pong"`。
  static const ping = 'ping';

  /// 返回平台 / 型号等设备信息 Map。
  static const getDeviceInfo = 'getDeviceInfo';

  /// 学习用：让原生同时通过 MethodChannel.emit 与 EventChannel 推一条事件。
  static const emitDemo = 'emitDemo';
}

/// Native → Flutter 事件名。
abstract final class NativeEventNames {
  /// 学习示例事件。
  static const demoTick = 'demo.tick';
}
