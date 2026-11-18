import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:all_flutter0709/core/cloud_storage/cloud_storage_service.dart';
import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:path/path.dart' as p;

class CommentImageUploadResult {
  const CommentImageUploadResult({
    required this.photoArrayJson,
    required this.picture,
  });

  final String photoArrayJson;
  final TopicPictureModel picture;
}

/// 单张评论图片上传；服务端仍沿用支持多张的 `photoarray` 数组格式。
abstract final class CommentImageUpload {
  static final Random _random = Random();

  static Future<CommentImageUploadResult> upload(File file) async {
    final service = CloudStorageService();
    final result = await service.uploadFileResult(
      file: file,
      key: _buildObjectKey(file.path),
    );
    final photoJson = result.toTopicPhotoJson(
      fallbackSize: await _readImageSize(file),
    );
    return CommentImageUploadResult(
      photoArrayJson: jsonEncode(<Map<String, String>>[photoJson]),
      picture: TopicPictureModel.fromJson(photoJson),
    );
  }

  static String _buildObjectKey(String path) {
    var extension = p.extension(path).toLowerCase();
    if (extension.isEmpty) {
      extension = '.jpg';
    }
    return 'comment-${DateTime.now().millisecondsSinceEpoch}-'
        '${_random.nextInt(10000)}$extension';
  }

  static Future<(int, int)?> _readImageSize(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final size = (frame.image.width, frame.image.height);
      frame.image.dispose();
      codec.dispose();
      return size;
    } catch (_) {
      return null;
    }
  }
}
