import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:all_flutter0709/core/push/chat_push_log.dart';
import 'package:all_flutter0709/features/conversation/data/chat_video_file_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:video_compress/video_compress.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

/// 聊天视频发送前的本地处理：抽小封面、按体积决定是否压缩。
///
/// 压缩逐条进行。失败且原片不超过 [maxOriginalBytes] 时改发原片。
class ChatVideoPrepare {
  ChatVideoPrepare._();

  /// 超过此时长的视频在相册里不可选。
  static const maxDurationSeconds = 5 * 60;

  /// 原片不超过这个体积就直接传，不再压缩。
  static const skipCompressBytes = 30 * 1024 * 1024;

  /// 压缩失败时，原片超过这个体积就不再发送。
  static const maxOriginalBytes = 80 * 1024 * 1024;

  static const _coverTargetBytes = 20 * 1024;
  static const _coverLongEdge = 320;

  static Future<void> _queue = Future<void>.value();

  /// 抽取封面并写入沙盒。失败时返回 false，不阻断发送。
  static Future<bool> writeCover({
    required AssetEntity asset,
    required String filename,
  }) async {
    if (filename.trim().isEmpty) {
      return false;
    }
    try {
      final bytes = await _coverBytes(asset);
      if (bytes == null || bytes.isEmpty) {
        ChatSendLog.d('视频封面抽取失败，继续发送');
        return false;
      }
      final file = await ChatVideoFileStore.writeBytes(
        filename: filename,
        bytes: bytes,
      );
      ChatSendLog.d('视频封面已写入 ${file.path} bytes=${bytes.length}');
      return true;
    } catch (error) {
      ChatSendLog.d('视频封面写入失败，继续发送: $error');
      return false;
    }
  }

  /// 把相册视频准备成沙盒里待上传的文件。
  ///
  /// [destination] 是预计的 mp4 路径。跳过压缩或压缩失败改发原片时，后缀可能变成原片后缀。
  static Future<File> prepare({
    required AssetEntity asset,
    required File destination,
  }) {
    return _enqueue(() => _prepare(asset, destination));
  }

  static Future<T> _enqueue<T>(Future<T> Function() job) {
    final run = _queue.then((_) => job());
    _queue = run.then((_) {}, onError: (_) {});
    return run;
  }

  static Future<File> _prepare(AssetEntity asset, File destination) async {
    final source = await asset.originFile ?? await asset.file;
    if (source == null || !await source.exists()) {
      throw Exception('视频读取失败');
    }
    final length = await source.length();
    ChatSendLog.d('视频原片 ${source.path} bytes=$length');
    if (length <= 0) {
      throw Exception('视频读取失败');
    }
    if (length <= skipCompressBytes) {
      final target = _retarget(destination, path.extension(source.path));
      ChatSendLog.d('原片不超过 30MB，跳过压缩 -> ${target.path}');
      return _copyKeep(source, target);
    }

    try {
      final compressed = await _compress(source);
      final output = await _place(compressed, destination);
      ChatSendLog.d(
        '视频压缩完成 ${output.path} bytes=${await output.length()}',
      );
      return output;
    } catch (error) {
      ChatSendLog.d('视频压缩失败，改判断原片: $error');
      try {
        await VideoCompress.cancelCompression();
      } catch (_) {}
      if (length > maxOriginalBytes) {
        throw Exception('视频太大，发送失败');
      }
      final target = _retarget(destination, path.extension(source.path));
      ChatSendLog.d('压缩失败，改发原片 -> ${target.path}');
      return _copyKeep(source, target);
    }
  }

  static Future<File> _compress(File source) async {
    final info = await VideoCompress.compressVideo(
      source.path,
      quality: VideoQuality.Res1280x720Quality,
      deleteOrigin: false,
      includeAudio: true,
    );
    final fromFile = info?.file;
    if (fromFile != null &&
        await fromFile.exists() &&
        await fromFile.length() > 0) {
      return fromFile;
    }
    final rawPath = info?.path?.trim() ?? '';
    if (rawPath.isEmpty) {
      throw Exception('压缩结果为空');
    }
    final decoded = File(Uri.decodeFull(rawPath));
    final compressed = await decoded.exists() ? decoded : File(rawPath);
    if (!await compressed.exists() || await compressed.length() <= 0) {
      throw Exception('压缩结果为空');
    }
    return compressed;
  }

  static Future<Uint8List?> _coverBytes(AssetEntity asset) async {
    final edge = _coverEdge(asset.orientatedSize);
    final bytes = await asset.thumbnailDataWithOption(
      Platform.isIOS || Platform.isMacOS
          ? ThumbnailOption.ios(
              size: edge,
              format: ThumbnailFormat.jpeg,
              quality: 55,
              resizeContentMode: ResizeContentMode.fit,
            )
          : ThumbnailOption(
              size: edge,
              format: ThumbnailFormat.jpeg,
              quality: 55,
            ),
    );
    if (bytes == null || bytes.isEmpty) {
      return null;
    }
    if (bytes.length <= _coverTargetBytes) {
      return bytes;
    }
    final once = await _shrink(bytes, quality: 45, edge: edge);
    if (once != null && once.length <= _coverTargetBytes) {
      return once;
    }
    final twice = await _shrink(
      once ?? bytes,
      quality: 30,
      edge: const ThumbnailSize(240, 240),
    );
    final best = twice ?? once;
    if (best != null && best.length < bytes.length) {
      return best;
    }
    return bytes;
  }

  static Future<Uint8List?> _shrink(
    Uint8List bytes, {
    required int quality,
    required ThumbnailSize edge,
  }) async {
    try {
      final shrunk = await FlutterImageCompress.compressWithList(
        bytes,
        quality: quality,
        minWidth: edge.width,
        minHeight: edge.height,
        format: CompressFormat.jpeg,
      );
      if (shrunk.isEmpty) {
        return null;
      }
      return shrunk;
    } catch (error) {
      debugPrint('[ChatSend] 封面再压缩失败: $error');
      return null;
    }
  }

  static ThumbnailSize _coverEdge(Size size) {
    final width = size.width;
    final height = size.height;
    if (width <= 1 || height <= 1) {
      return const ThumbnailSize(_coverLongEdge, _coverLongEdge);
    }
    if (width >= height) {
      final short = (_coverLongEdge * height / width).round().clamp(
        1,
        _coverLongEdge,
      );
      return ThumbnailSize(_coverLongEdge, short.toInt());
    }
    final short = (_coverLongEdge * width / height).round().clamp(
      1,
      _coverLongEdge,
    );
    return ThumbnailSize(short.toInt(), _coverLongEdge);
  }

  static File _retarget(File destination, String extension) {
    final normalized = extension.trim().toLowerCase();
    final suffix = normalized.isEmpty
        ? '.mp4'
        : (normalized.startsWith('.') ? normalized : '.$normalized');
    final without = destination.path.replaceFirst(RegExp(r'\.[^.]+$'), '');
    return File('$without$suffix');
  }

  static Future<File> _copyKeep(File source, File target) async {
    if (source.path == target.path) {
      return target;
    }
    await target.parent.create(recursive: true);
    if (await target.exists()) {
      await target.delete();
    }
    return source.copy(target.path);
  }

  static Future<File> _place(File source, File target) async {
    if (source.path == target.path) {
      return target;
    }
    await target.parent.create(recursive: true);
    if (await target.exists()) {
      await target.delete();
    }
    try {
      return await source.rename(target.path);
    } on FileSystemException {
      final copied = await source.copy(target.path);
      try {
        await source.delete();
      } catch (_) {}
      return copied;
    }
  }
}
