import 'package:flutter/foundation.dart';

/// 聊天推送联调日志。logcat 过滤：`adb logcat | grep ChatPush`
abstract final class ChatPushLog {
  static const tag = 'ChatPush';

  static void d(String message) {
    debugPrint('[$tag] $message');
  }
}

/// 聊天发送联调日志。logcat 过滤：`adb logcat | grep ChatSend`
abstract final class ChatSendLog {
  static const tag = 'ChatSend';

  static void d(String message) {
    debugPrint('[$tag] $message');
  }
}
