import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 头像、封面共用的正方形 JPEG 限制。
///
/// 最长边 1024，体积压到 300KB 以内。1024 压不进去再缩到 720。
abstract final class SquareJpegFit {
  /// 首选最长边。
  static const edge = 1024;

  /// 1024 压不进 [maxBytes] 时再退到这一档。
  static const fallbackEdge = 720;

  /// 上传体积上限。
  static const maxBytes = 300 * 1024;

  /// 把已裁好的图压成符合上限的 JPEG。压缩失败时返回原文件。
  static Future<File> fit(File file) async {
    const steps = <({int quality, int edge})>[
      (quality: 80, edge: edge),
      (quality: 65, edge: edge),
      (quality: 50, edge: edge),
      (quality: 70, edge: fallbackEdge),
      (quality: 55, edge: fallbackEdge),
    ];
    File? smallest;
    var smallestBytes = 1 << 62;
    for (final step in steps) {
      final output = await _encodeJpeg(
        file,
        quality: step.quality,
        edge: step.edge,
      );
      if (output == null) {
        continue;
      }
      final bytes = await output.length();
      if (bytes <= 0 || bytes >= smallestBytes) {
        continue;
      }
      smallest = output;
      smallestBytes = bytes;
      if (bytes <= maxBytes) {
        return output;
      }
    }
    return smallest ?? file;
  }

  static Future<File?> _encodeJpeg(
    File file, {
    required int quality,
    required int edge,
  }) async {
    final directory = await getTemporaryDirectory();
    final targetPath = p.join(
      directory.path,
      'square-jpeg-${DateTime.now().microsecondsSinceEpoch}.jpg',
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
}
