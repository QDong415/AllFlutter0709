import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 压缩后准备上传的文件和对象名。
class PreparedUploadModel {
  const PreparedUploadModel({required this.file, required this.key});

  final File file;
  final String key;
}

/// 走 S3 前处理静态图。上限由调用方传入，单位 MB。
///
/// CloudFront 能直接打开 jpg/jpeg、png、webp、gif、tif/tiff、avif。
/// 相册里常见、但它打不开的是 heic/heif、bmp，这些一律转成 JPEG。
/// 能打开的格式只在超过上限时压缩。上限 `<= 0` 时不按体积压缩。
/// 视频、语音不处理。七牛不调用本类。
class ImageUploadLimiter {
  /// CloudFront 图片处理能直接打开的后缀。
  static const _supportedExtensions = <String>{
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.gif',
    '.tif',
    '.tiff',
    '.avif',
  };

  /// 相册里会选到、但 CloudFront 会返回 RequestTypeError 的后缀。
  static const _unsupportedExtensions = <String>{
    '.heic',
    '.heif',
    '.bmp',
  };

  static const _steps = <({int quality, int edge})>[
    (quality: 85, edge: 2560),
    (quality: 75, edge: 2048),
    (quality: 65, edge: 1600),
    (quality: 50, edge: 1280),
    (quality: 40, edge: 960),
  ];

  /// 不支持的格式，或超过 [maxMb] 时返回 JPEG，并把对象名后缀改成 `.jpg`。
  ///
  /// 只由 S3 上传调用。动态、聊天、头像都走这个入口。七牛不会进这里。
  static Future<PreparedUploadModel> prepare({
    required File file,
    required String key,
    required int maxMb,
  }) async {
    final original = PreparedUploadModel(file: file, key: key);
    final extension = _extensionOf(file.path, key);
    final mustConvert = _unsupportedExtensions.contains(extension);
    // 视频、语音和其他非图片不转码。
    if (!mustConvert && !_supportedExtensions.contains(extension)) {
      return original;
    }

    final maxBytes = maxMb > 0 ? maxMb * 1024 * 1024 : 0;
    // 上限 <= 0 表示不限制体积。能打开的格式不再压缩；HEIC、BMP 仍要转 JPEG。
    if (!mustConvert && maxBytes <= 0) {
      return original;
    }

    final originalBytes = await file.length();
    final overLimit = maxBytes > 0 && originalBytes > maxBytes;
    // JPG、PNG、WebP、GIF、TIFF、AVIF 没超过上限就保持原文件。
    if (!mustConvert && !overLimit) {
      return original;
    }

    try {
      final jpeg = await _toJpeg(
        file,
        // 不支持的格式必须换成 JPEG，即使转完比原文件大。
        acceptAnyJpeg: mustConvert,
        // 没超上限时只换格式，尽量不缩小；超上限再逐级压缩。
        keepSize: mustConvert && !overLimit,
        originalBytes: originalBytes,
        maxBytes: maxBytes,
      );
      // 转码失败时仍上传原图，避免这条消息发不出去。
      if (jpeg == null) {
        debugPrint(
          '[ImageUpload] 压缩失败，按原图上传 bytes=$originalBytes limit=$maxBytes',
        );
        return original;
      }
      final uploadKey = _jpegKey(key);
      debugPrint(
        '[ImageUpload] $originalBytes -> ${jpeg.lengthSync()} '
        'limit=$maxBytes key=$uploadKey',
      );
      return PreparedUploadModel(file: jpeg, key: uploadKey);
    } catch (error) {
      debugPrint('[ImageUpload] 压缩异常，按原图上传: $error');
      return original;
    }
  }

  /// [keepSize] 时先按原尺寸转 JPEG。转完仍超上限，或本来就超上限，再逐级缩小。
  static Future<File?> _toJpeg(
    File file, {
    required bool acceptAnyJpeg,
    required bool keepSize,
    required int originalBytes,
    required int maxBytes,
  }) async {
    if (keepSize) {
      final converted = await _encodeJpeg(file, quality: 92, edge: 8192);
      if (await _withinLimit(converted, maxBytes)) {
        return converted;
      }
    }

    File? smallest;
    var smallestBytes = acceptAnyJpeg ? 1 << 62 : originalBytes;
    for (final step in _steps) {
      final output = await _encodeJpeg(
        file,
        quality: step.quality,
        edge: step.edge,
      );
      final bytes = output == null ? 0 : await output.length();
      if (output == null || bytes <= 0 || bytes >= smallestBytes) {
        continue;
      }
      smallest = output;
      smallestBytes = bytes;
      if (maxBytes > 0 && bytes <= maxBytes) {
        break;
      }
    }
    return smallest;
  }

  static Future<bool> _withinLimit(File? file, int maxBytes) async {
    if (file == null) {
      return false;
    }
    final bytes = await file.length();
    return bytes > 0 && (maxBytes <= 0 || bytes <= maxBytes);
  }

  static Future<File?> _encodeJpeg(
    File file, {
    required int quality,
    required int edge,
  }) async {
    final directory = await getTemporaryDirectory();
    final targetPath = p.join(
      directory.path,
      'upload-limit-${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    final compressed = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
      minWidth: edge,
      minHeight: edge,
      format: CompressFormat.jpeg,
    );
    if (compressed == null) {
      return null;
    }
    return File(compressed.path);
  }

  static String _extensionOf(String filePath, String key) {
    final extension = p.extension(filePath).toLowerCase();
    if (extension.isNotEmpty) {
      return extension;
    }
    return p.extension(key).toLowerCase();
  }

  static String _jpegKey(String key) {
    final extension = p.extension(key).toLowerCase();
    if (extension == '.jpg' || extension == '.jpeg') {
      return key;
    }
    if (extension.isEmpty) {
      return '$key.jpg';
    }
    return '${p.withoutExtension(key)}.jpg';
  }
}
