import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:all_flutter0709/core/cloud_storage/cloud_storage_service.dart';
import 'package:all_flutter0709/features/topic/data/models/topic_submit_media_model.dart';
import 'package:flutter/foundation.dart';

/// 举报附图上传，输出 `photoarray` JSON（与发动态一致）。
class OpinionPhotoSubmitHelper {
  const OpinionPhotoSubmitHelper(this._cloudStorageService);

  final CloudStorageService _cloudStorageService;

  static const int maxImageCount = 9;

  Future<String?> buildPhotoArrayJson(List<TopicSubmitMediaModel> mediaList) async {
    if (mediaList.isEmpty) {
      return null;
    }
    final photoJsonList = <Map<String, String>>[];
    for (var index = 0; index < mediaList.length; index++) {
      final mediaModel = mediaList[index];
      final key = 'photo-${DateTime.now().millisecondsSinceEpoch}-$index.jpg';
      final result = await _cloudStorageService.uploadFileResult(
        file: mediaModel.file,
        key: key,
      );
      final fallbackSize = await _readImageSize(mediaModel.file);
      photoJsonList.add(result.toTopicPhotoJson(fallbackSize: fallbackSize));
    }
    return jsonEncode(photoJsonList);
  }

  Future<(int, int)?> _readImageSize(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return (frame.image.width, frame.image.height);
    } catch (error) {
      debugPrint('[OpinionPhotoSubmit] read image size failed: $error');
      return null;
    }
  }
}
