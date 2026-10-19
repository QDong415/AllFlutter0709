import 'dart:convert';

import 'package:all_flutter0709/core/auth/auth_vendor_config.dart';
import 'package:all_flutter0709/core/network/app_env.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 阿里云验证码 2.0（Webview+H5）。通过时返回 captchaVerifyParam。
class AliyunCaptchaPage extends StatefulWidget {
  const AliyunCaptchaPage({super.key});

  /// 弹出验证码。用户关闭或失败时返回 null。
  static Future<String?> show(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const AliyunCaptchaPage()),
    );
  }

  @override
  State<AliyunCaptchaPage> createState() => _AliyunCaptchaPageState();
}

class _AliyunCaptchaPageState extends State<AliyunCaptchaPage> {
  late final WebViewController _controller;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'CaptchaBridge',
        onMessageReceived: (message) {
          _onMessage(message.message);
        },
      )
      ..loadHtmlString(_html(), baseUrl: AppEnv.siteBaseUrl);
  }

  void _onMessage(String raw) {
    if (_finished || !mounted) {
      return;
    }
    final text = raw.trim();
    if (text.isEmpty) {
      return;
    }
    if (text.startsWith('{')) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map && decoded['failed'] == true) {
          _close(null);
          return;
        }
      } catch (_) {
        // 验签参数本身是 JSON 字符串，原样交给服务端。
      }
    }
    _close(text);
  }

  void _close(String? value) {
    if (_finished) {
      return;
    }
    _finished = true;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('安全验证'),
        leading: IconButton(
          onPressed: () => _close(null),
          icon: const Icon(Icons.close),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

String _html() {
  final prefix = jsonEncode(AuthVendorConfig.captchaPrefix);
  final sceneId = jsonEncode(AuthVendorConfig.captchaSceneId);
  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <script>
    window.AliyunCaptchaConfig = { region: "cn", prefix: $prefix };
  </script>
  <script src="https://o.alicdn.com/captcha-frontend/aliyunCaptcha/AliyunCaptcha.js"></script>
</head>
<body>
  <div id="captcha-element"></div>
  <button id="captcha-button" type="button" style="display:none">验证</button>
  <script>
    function boot() {
      if (typeof initAliyunCaptcha !== "function") {
        setTimeout(boot, 200);
        return;
      }
      initAliyunCaptcha({
        SceneId: $sceneId,
        mode: "popup",
        element: "#captcha-element",
        button: "#captcha-button",
        language: "cn",
        success: function (captchaVerifyParam) {
          CaptchaBridge.postMessage(String(captchaVerifyParam));
        },
        fail: function () {
          CaptchaBridge.postMessage(JSON.stringify({ failed: true }));
        }
      });
      setTimeout(function () {
        var button = document.getElementById("captcha-button");
        if (button) button.click();
      }, 400);
    }
    boot();
  </script>
</body>
</html>
''';
}
