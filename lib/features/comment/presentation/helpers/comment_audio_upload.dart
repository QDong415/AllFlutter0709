import 'dart:io';
import 'dart:math';

import 'package:all_flutter0709/core/cloud_storage/cloud_storage_service.dart';
import 'package:all_flutter0709/core/config/app_config.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

/// 评论语音上传，与动态语音同一存储规则。
abstract final class CommentAudioUpload {
  static final Random _random = Random();

  static Future<String> upload(File file) async {
    final service = CloudStorageService();
    String? token;
    if (AppConfig.instance.cloudStorage != CloudStorage.s3) {
      token = await service.fetchQiniuUploadToken();
    }
    final result = await service.uploadFileResult(
      file: file,
      key: _buildObjectKey(file.path),
      token: token,
    );
    return result.key;
  }

  static String _buildObjectKey(String path) {
    final time = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    var ext = p.extension(path);
    if (ext.isEmpty) {
      ext = '.m4a';
    }
    return 'topic-$time-90-${_random.nextInt(10000)}$ext';
  }
}