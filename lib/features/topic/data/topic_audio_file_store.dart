import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 动态语音的本地文件。按对象文件名落盘，完整 URL 只取最后一段。
abstract final class TopicAudioFileStore {
  /// 返回 [filename] 对应的本地文件。目录不存在时会创建。
  static Future<File> fileForName(String filename) async {
    final directory = await getApplicationSupportDirectory();
    final folder = Directory('${directory.path}${Platform.pathSeparator}topic_audio');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return File('${folder.path}${Platform.pathSeparator}${baseName(filename)}');
  }

  /// 本地已有且非空的缓存文件；否则为 null。
  static Future<File?> cachedFileForName(String filename) async {
    final name = filename.trim();
    if (name.isEmpty) {
      return null;
    }
    final file = await fileForName(name);
    if (await file.exists() && await file.length() > 0) {
      return file;
    }
    return null;
  }

  /// 对象名或 URL 的文件名部分。
  static String baseName(String filename) {
    final value = filename.trim();
    final uri = Uri.tryParse(value);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return p.basename(uri.pathSegments.last);
    }
    return p.basename(value);
  }
}
