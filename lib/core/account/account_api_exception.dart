/// 账号接口返回的业务错误。
class AccountApiException implements Exception {
  AccountApiException(this.message, {this.code = 0});

  /// 服务端文案。
  final String message;

  /// 服务端 code。验证码登录未注册为 -2。
  final int code;

  /// 手机号尚未注册。
  bool get isUnregistered => code == -2;

  @override
  String toString() => message;
}
