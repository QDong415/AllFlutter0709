import Flutter
import UIKit
import getuiflut

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UISceneConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    GetuiflutPlugin.handleSceneWillConnect(withOptions: connectionOptions)
  }
}
