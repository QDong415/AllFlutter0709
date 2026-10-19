/// 客户端调试开关。只影响界面和本地测试分支，不改服务端。
abstract final class AppFlags {
  /// 为 true 时展示登录/注册里的测试文案，并允许验证码填 `0000` 直接走注册。
  static const bool testLogin = false;
}
