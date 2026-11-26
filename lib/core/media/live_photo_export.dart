import 'dart:io';

import 'package:all_flutter0709/core/media/video_upload_prepare.dart';
import 'package:flutter/foundation.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

/// 从 iOS Live 图导出配对短视频，并压成 Android 能播的 MP4。
class LivePhotoExport {
  LivePhotoExport._();

  /// 导出配对视频原文件。不是 Live，或系统没有配对视频时返回 null。
  static Future<File?> pairedVideoFile(AssetEntity asset) async {
    if (!asset.isLivePhoto) {
      return null;
    }
    try {
      final file = await asset.loadFile(
        isOrigin: true,
        withSubtype: true,
        darwinFileType: PMDarwinAVFileType.mp4,
      );
      if (file == null || !await file.exists()) {
        return null;
      }
      final length = await file.length();
      if (length <= 0) {
        return null;
      }
      return file;
    } catch (error) {
      debugPrint('[LivePhoto] 导出配对视频失败: $error');
      return null;
    }
  }

  /// 导出配对视频并强制压成 720p H.264。读不到或压缩失败时抛出异常。
  static Future<File> compressedPairedVideo({
    required AssetEntity asset,
    Object? owner,
    bool Function()? isCancelled,
  }) async {
    final paired = await pairedVideoFile(asset);
    if (isCancelled?.call() == true) {
      throw const VideoPrepareCancelled();
    }
    if (paired == null) {
      throw Exception('实况视频读取失败');
    }
    final oriented = asset.orientatedSize;
    return VideoUploadPrepare.prepare(
      source: paired,
      width: oriented.width.round(),
      height: oriented.height.round(),
      owner: owner,
      isCancelled: isCancelled,
      force: true,
      allowOriginalFallback: false,
    );
  }
}
