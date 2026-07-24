import Flutter
import UIKit

/// iOS 侧原生 Bridge：注册 MethodChannel + EventChannel，处理 Flutter `call`。
///
/// 通道名与 Dart NativeChannels 对齐：
/// - MethodChannel: com.dq.allflutter0709/bridge
/// - EventChannel:  com.dq.allflutter0709/events
final class NativeBridge: NSObject, FlutterStreamHandler {
  static let methodChannelName = "com.dq.allflutter0709/bridge"
  static let eventChannelName = "com.dq.allflutter0709/events"

  private static let methodCall = "call"
  private static let methodEmit = "emit"

  private static let apiPing = "ping"
  private static let apiGetDeviceInfo = "getDeviceInfo"
  private static let apiEmitDemo = "emitDemo"

  private static let eventDemoTick = "demo.tick"

  private let methodChannel: FlutterMethodChannel
  private var eventSink: FlutterEventSink?

  private init(messenger: FlutterBinaryMessenger) {
    methodChannel = FlutterMethodChannel(
      name: NativeBridge.methodChannelName,
      binaryMessenger: messenger
    )
    super.init()

    methodChannel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }

    let eventChannel = FlutterEventChannel(
      name: NativeBridge.eventChannelName,
      binaryMessenger: messenger
    )
    eventChannel.setStreamHandler(self)
  }

  /// 在 Implicit Engine 就绪后注册通道。
  @discardableResult
  static func register(messenger: FlutterBinaryMessenger) -> NativeBridge {
    NativeBridge(messenger: messenger)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case NativeBridge.methodCall:
      handleCall(arguments: call.arguments, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleCall(arguments: Any?, result: @escaping FlutterResult) {
    guard let payload = arguments as? [String: Any] else {
      result(
        FlutterError(
          code: "bad_args",
          message: "call 参数必须是 Map",
          details: nil
        )
      )
      return
    }

    let api = payload["api"] as? String
    switch api {
    case NativeBridge.apiPing:
      result("pong")
    case NativeBridge.apiGetDeviceInfo:
      result(buildDeviceInfo())
    case NativeBridge.apiEmitDemo:
      emitDemo()
      result(true)
    default:
      result(
        FlutterError(
          code: "unknown_api",
          message: "未知 api: \(api ?? "nil")",
          details: nil
        )
      )
    }
  }

  private func buildDeviceInfo() -> [String: Any] {
    let device = UIDevice.current
    return [
      "platform": "ios",
      "name": device.name,
      "model": device.model,
      "systemName": device.systemName,
      "systemVersion": device.systemVersion,
      "identifierForVendor": device.identifierForVendor?.uuidString ?? "",
    ]
  }

  /// 学习用：同一时刻走两条通道各推一条 demo.tick，方便对比。
  private func emitDemo() {
    let now = Int(Date().timeIntervalSince1970 * 1000)
    methodChannel.invokeMethod(
      NativeBridge.methodEmit,
      arguments: [
        "v": 1,
        "event": NativeBridge.eventDemoTick,
        "data": [
          "via": "method",
          "ts": now,
          "platform": "ios",
        ],
      ]
    )
    eventSink?(
      [
        "v": 1,
        "event": NativeBridge.eventDemoTick,
        "data": [
          "via": "eventChannel",
          "ts": now,
          "platform": "ios",
        ],
      ]
    )
  }
}
