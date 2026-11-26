import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:all_flutter0709/core/cloud_storage/cloud_storage_service.dart';
import 'package:all_flutter0709/core/cloud_storage/cloud_storage_upload_result.dart';
import 'package:all_flutter0709/core/media/live_photo_export.dart';
import 'package:all_flutter0709/features/conversation/presentation/helpers/chat_video_prepare.dart';
import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

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
    final result = await _put(file);
    final photoJson = result.toTopicPhotoJson(
      fallbackSize: await _readImageSize(file),
    );
    return _result(photoJson);
  }

  /// 先传静图。配对视频失败时退回普通图片，静图失败则抛出。
  static Future<CommentImageUploadResult> uploadLive({
    required File still,
    required AssetEntity asset,
  }) async {
    final result = await _put(still);
    final photoJson = result.toTopicPhotoJson(
      fallbackSize: await _readImageSize(still),
    );
    try {
      final videoFile = await LivePhotoExport.compressedPairedVideo(
        asset: asset,
      );
      if (await videoFile.exists() && await videoFile.length() > 0) {
        final video = await _put(videoFile);
        if (video.key.trim().isNotEmpty) {
          photoJson['videourl'] = video.key.trim();
        }
      }
    } catch (_) {}
    return _result(photoJson);
  }

  /// 封面和视频都要成功。任一失败则整条评论不入库。
  static Future<CommentImageUploadResult> uploadVideo({
    required File cover,
    required AssetEntity asset,
    required int durationSeconds,
  }) async {
    final coverResult = await _put(cover);
    final photoJson = coverResult.toTopicPhotoJson(
      fallbackSize: await _readImageSize(cover),
    );
    final oriented = asset.orientatedSize;
    if (oriented.width > 1 && oriented.height > 1) {
      photoJson['width'] = '${oriented.width.round()}';
      photoJson['height'] = '${oriented.height.round()}';
    }
    final directory = await getTemporaryDirectory();
    final destination = File(
      '${directory.path}${Platform.pathSeparator}'
      'comment_video_${DateTime.now().microsecondsSinceEpoch}.mp4',
    );
    final videoFile = await ChatVideoPrepare.prepare(
      asset: asset,
      destination: destination,
    );
    final video = await _put(videoFile);
    if (video.key.trim().isEmpty) {
      throw Exception('视频上传失败');
    }
    photoJson['videourl'] = video.key.trim();
    final seconds = durationSeconds <= 0 ? 1 : durationSeconds;
    photoJson['duration'] = '$seconds';
    return _result(photoJson);
  }

  static Future<CloudStorageUploadResult> _put(File file) {
    return CloudStorageService().uploadFileResult(
      file: file,
      key: _buildObjectKey(file.path),
    );
  }

  static CommentImageUploadResult _result(Map<String, String> photoJson) {
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
