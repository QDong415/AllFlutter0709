import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 聊天图片的本地副本，放在 Application Support，系统不会像 tmp 那样回收。
abstract final class ChatImageFileStore {
  /// 把选图得到的临时文件复制到持久目录，文件名与上传用的 [filename] 相同。
  static Future<File> persist({
    required File sourceFile,
    required String filename,
  }) async {
    final directory = Directory(
      '${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}chat_images',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final targetFile = File(
      '${directory.path}${Platform.pathSeparator}$filename',
    );
    if (sourceFile.path == targetFile.path) {
      return sourceFile;
    }
    if (await targetFile.exists()) {
      return targetFile;
    }
    return sourceFile.copy(targetFile.path);
  }
}
