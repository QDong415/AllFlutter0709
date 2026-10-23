import 'dart:convert';

import 'package:crypto/crypto.dart';

/// 与 Buddy `NetWorkCallback.configParams` 相同的请求签名。
class RequestSign {
  RequestSign._();

  /// 参与签名的密钥，和 Buddy `HttpUtil.SIG_KEY`、PHP `SIGN_KEY` 一致。
  static const signKey = 'iTopic2015';

  /// 计算 `sig`。
  ///
  /// 先把 `sig` 写成 [signKey]，再按 key 升序拼成 `k=v&k=v`（value 不做 URL 编码），
  /// 对 UTF-8 字节做 MD5。返回小写十六进制，调用方用它覆盖最终的 `sig`。
  static String sign(Map<String, String> paramsMap) {
    final signedMap = Map<String, String>.from(paramsMap);
    signedMap['sig'] = signKey;
    final keyList = signedMap.keys.toList()..sort();
    final buffer = StringBuffer();
    for (var i = 0; i < keyList.length; i++) {
      if (i != 0) {
        buffer.write('&');
      }
      final key = keyList[i];
      buffer
        ..write(key)
        ..write('=')
        ..write(signedMap[key] ?? '');
    }
    return md5.convert(utf8.encode(buffer.toString())).toString();
  }
}
