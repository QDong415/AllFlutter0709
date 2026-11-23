import 'dart:io';

import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';
import 'package:path_provider/path_provider.dart';

/// 聊天视频和封面的本地副本，放在 Application Support，系统不会像 tmp 那样回收。
abstract final class ChatVideoFileStore {
  static String? _directoryPath;

  /// 视频对象在沙盒中的绝对路径，并确保目录存在。
  static Future<String> pathFor(String filename) async {
    final directory = await _directory();
    return '${directory.path}${Platform.pathSeparator}$filename';
  }

  /// 把封面字节写进沙盒，文件名与上传用的对象名相同。
  static Future<File> writeBytes({
    required String filename,
    required List<int> bytes,
  }) async {
    final file = File(await pathFor(filename));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// 沙盒里已经存在的文件路径。目录还没初始化，或文件不存在时返回 null。
  static String? existingPath(String filename) {
    final directoryPath = _directoryPath;
    final name = filename.trim();
    if (directoryPath == null ||
        name.isEmpty ||
        name.contains(Platform.pathSeparator)) {
      return null;
    }
    final path = '$directoryPath${Platform.pathSeparator}$name';
    if (!File(path).existsSync()) {
      return null;
    }
    return path;
  }

  /// 对象名后缀变化后，把沙盒里的旧文件改成新名字。
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
    final directory = await _directory();
    final separator = Platform.pathSeparator;
    final oldFile = File('${directory.path}$separator$oldName');
    if (!await oldFile.exists()) {
      return null;
    }
    final newFile = File('${directory.path}$separator$newName');
    if (await newFile.exists()) {
      return newFile.path;
    }
    return (await oldFile.rename(newFile.path)).path;
  }

  /// 用当前沙盒目录拼视频 [ConversationMessage.filename]。容器 ID 变了也不写回数据库。
  static Future<List<ConversationMessage>> withCurrentFiles(
    List<ConversationMessage> messages,
  ) async {
    final directory = await _directory();
    final separator = Platform.pathSeparator;
    return [
      for (final message in messages)
        _withCurrentVideoFile(message, directory.path, separator),
    ];
  }

  static ConversationMessage _withCurrentVideoFile(
    ConversationMessage message,
    String directory,
    String separator,
  ) {
    if (!message.isVideo) {
      return message;
    }
    final name = message.filename.trim();
    if (name.isEmpty || name.contains(separator)) {
      return message;
    }
    final currentPath = '$directory$separator$name';
    if (!File(currentPath).existsSync() ||
        message.localFilePath == currentPath) {
      return message;
    }
    return message.copyWith(localFilePath: currentPath);
  }

  static Future<Directory> _directory() async {
    final directory = Directory(
      '${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}chat_videos',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    _directoryPath = directory.path;
    return directory;
  }
}
