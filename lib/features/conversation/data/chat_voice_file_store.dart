import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 聊天语音本地文件：对齐 Android `filesDir/filename`。
abstract final class ChatVoiceFileStore {
  static const maxDurationSeconds = 60;
  static const minDurationMilliseconds = 1000;
  static const fileExtension = '.wav';

  /// 生成七牛 key / 本地文件名，对齐 Android `currentTimeMillis + ".wav"`。
  static String buildFileName() {
    return '${DateTime.now().millisecondsSinceEpoch}$fileExtension';
  }

  /// 返回 [filename] 对应的本地绝对路径。
  static Future<String> pathForFileName(String filename) async {
    final directory = await getApplicationSupportDirectory();
    return '${directory.path}${Platform.pathSeparator}$filename';
  }
}
