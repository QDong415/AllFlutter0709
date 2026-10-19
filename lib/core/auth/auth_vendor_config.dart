import 'dart:io';

import 'package:flutter/foundation.dart';

/// 友盟一键登录、阿里云验证码 2.0 的客户端参数。
///
/// 对应密钥留空时该功能不启用，短信登录仍可使用。
/// 服务端验签参数在 `config/common.php`。
abstract final class AuthVendorConfig {
  /// 友盟 Android 应用 AppKey。服务端换号也用这一把。
  static const androidAppKey = '55a067dd67e58e715500691f';

  /// 友盟 iOS 应用 AppKey。服务端换号也用这一把。
  static const iosAppKey = '55c95d2ce0f55af81d0030c8';

  /// 友盟智能认证 Android 方案密钥。
  static const androidVerifySecret =
      '38vcPFGwAFu3jASgLdiN61ZmithKw0ulW/x7WdbWTBG5FaI2oANlnee/ajI+J2ZJi7GNXyoTx7POWHcBW0dsRUB3B98rl5OBueQotxi2TMnH6rT7diPCczLgEWYa+eik564GmDzXBlJk0oTYzmas2nyYdm5KZWkwfBwD3ofKR+4QBgWb1ylM9VupvF17ZzlDr3ZdGkrKR5SuUPP6kwSbWD7m1OJ7Q6Gww5dcyfFQ6Sxa+Io5F7KK0rBVoJNXUm/WCYdobcvQpRiGVp+7Zxpjccy2AJVqN1vSITySg3acqR4=';

  /// 友盟智能认证 iOS 方案密钥。
  static const iosVerifySecret =
      'AhCOhkG6TWpVeVJIChi+FZGbumH602ePxXOatAu94JhuSqzeXyC5JN5qXLtL4siyfSUdqL/hhjbzabFj6lI2oimrLZ42gNGDZ09h4pc6ryO6F3//BcfdXdFu7kzZll7GF4Oet3PzpObLLdqYHmTnOniTPElJh+edu31ybRH9bY4tJ8vlPxzMURSHyG5K7ItkbBXu8td2V/DlIyju3qwvnXJrWp289y41lLe48XZU5y4nI+cakLEKve/iqjCFLXhv';

  /// 阿里云验证码 2.0 身份标（控制台概览）。
  static const captchaPrefix = 'am2uwq';

  /// 阿里云验证码 2.0 场景 ID。客户端场景须选 Webview+H5。
  static const captchaSceneId = '1xtq8b47';

  /// 当前平台是否已填一键登录方案密钥。
  static bool get oneTapEnabled {
    if (kIsWeb) {
      return false;
    }
    if (Platform.isAndroid) {
      return androidVerifySecret.trim().isNotEmpty;
    }
    if (Platform.isIOS) {
      return iosVerifySecret.trim().isNotEmpty;
    }
    return false;
  }

  /// 是否已填验证码 2.0 的身份标和场景 ID。
  static bool get captchaEnabled {
    return captchaPrefix.trim().isNotEmpty && captchaSceneId.trim().isNotEmpty;
  }
}
