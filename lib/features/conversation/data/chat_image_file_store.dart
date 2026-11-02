import 'dart:io';

import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';
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
    if (sourceFile.path == targetFile.path || await targetFile.exists()) {
      return targetFile;
    }
    return sourceFile.copy(targetFile.path);
  }

  /// S3 转 JPEG 后对象名后缀会变；把沙盒里旧文件改成新名字，返回新绝对路径。
  static Future<String?> renameLocalCopy({
    required String oldFilename,
    required String newFilename,
  }) async {
    final oldName = oldFilename.trim();
    final newName = newFilename.trim();
    if (oldName.isEmpty ||
        newName.isEmpty ||
        oldName == newName ||
        oldName.contains(Platform.pathSeparator) ||
        newName.contains(Platform.pathSeparator)) {
      return null;
    }
    final separator = Platform.pathSeparator;
    final directory =
        '${(await getApplicationSupportDirectory()).path}${separator}chat_images';
    final oldFile = File('$directory$separator$oldName');
    if (!await oldFile.exists()) {
      return null;
    }
    final newFile = File('$directory$separator$newName');
    if (await newFile.exists()) {
      return newFile.path;
    }
    return (await oldFile.rename(newFile.path)).path;
  }

  /// 用当前沙盒目录拼 [ConversationMessage.filename]。容器 ID 变了也不写回数据库。
  static Future<List<ConversationMessage>> withCurrentFiles(
    List<ConversationMessage> messages,
  ) async {
    final separator = Platform.pathSeparator;
    final directory =
        '${(await getApplicationSupportDirectory()).path}${separator}chat_images';
    return [
      for (final message in messages)
        _withCurrentImageFile(message, directory, separator),
    ];
  }

  static ConversationMessage _withCurrentImageFile(
    ConversationMessage message,
    String directory,
    String separator,
  ) {
    if (!message.isImage) {
      return message;
    }
    final name = message.filename.trim();
    if (name.isEmpty || name.contains(separator)) {
      return message;
    }
    final currentPath = '$directory$separator$name';
    if (!File(currentPath).existsSync() || message.localFilePath == currentPath) {
      return message;
    }
    return message.copyWith(localFilePath: currentPath);
  }
}
