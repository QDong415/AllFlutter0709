import Flutter
import UIKit
import getuiflut

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
      GetuiflutPlugin.handleSceneWillConnect(with: connectionOptions)
  }
}
