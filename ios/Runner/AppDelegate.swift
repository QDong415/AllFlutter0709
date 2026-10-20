import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let authChannelName = "com.dq.itopic/umeng_auth"
  private static let umengAppKey = "55c95d2ce0f55af81d0030c8"
  private static let umengVerifySecret =
    "AhCOhkG6TWpVeVJIChi+FZGbumH602ePxXOatAu94JhuSqzeXyC5JN5qXLtL4siyfSUdqL/hhjbzabFj6lI2oimrLZ42gNGDZ09h4pc6ryO6F3//BcfdXdFu7kzZll7GF4Oet3PzpObLLdqYHmTnOniTPElJh+edu31ybRH9bY4tJ8vlPxzMURSHyG5K7ItkbBXu8td2V/DlIyju3qwvnXJrWp289y41lLe48XZU5y4nI+cakLEKve/iqjCFLXhv"

  /// 必须强引用，否则 Channel handler 闭包里的 weak self 会失效。
  private var nativeBridge: NativeBridge?
  private var authChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UmengAuthBootstrap.start(
      withAppKey: Self.umengAppKey,
      verifySecret: Self.umengVerifySecret,
      channel: "App Store"
    )
    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    completionHandler(.noData)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    nativeBridge = NativeBridge.register(
      messenger: engineBridge.applicationRegistrar.messenger()
    )
    let channel = FlutterMethodChannel(
      name: Self.authChannelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "waitUntilPrepared" else {
        result(FlutterMethodNotImplemented)
        return
      }
      UmengAuthBootstrap.wait(untilPrepared: { preparationResult in
        result(preparationResult)
      })
    }
    authChannel = channel
  }
}
