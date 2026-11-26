import 'dart:io';
import 'dart:typed_data';

import 'package:all_flutter0709/core/media/live_photo_export.dart';
import 'package:all_flutter0709/core/media/video_upload_prepare.dart';
import 'package:all_flutter0709/core/push/chat_push_log.dart';
import 'package:all_flutter0709/features/conversation/data/chat_video_file_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

/// 聊天视频发送前的本地处理：抽小封面，并交给 [VideoUploadPrepare] 压缩。
class ChatVideoPrepare {
  ChatVideoPrepare._();

  static const _coverTargetBytes = 20 * 1024;
  static const _coverLongEdge = 320;

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

  /// 抽出封面写到临时目录。读不到封面时抛出。
  static Future<File> tempCoverFile(AssetEntity asset) async {
    final bytes = await _coverBytes(asset);
    if (bytes == null || bytes.isEmpty) {
      throw Exception('视频封面读取失败');
    }
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}'
      'video_cover_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// 把相册视频准备成沙盒里待上传的文件。
  ///
  /// [destination] 是预计的 mp4 路径。跳过压缩或压缩失败改发原片时，后缀可能变成原片后缀。
  static Future<File> prepare({
    required AssetEntity asset,
    required File destination,
  }) {
    return _prepare(asset, destination);
  }

  static Future<File> _prepare(AssetEntity asset, File destination) async {
    final source = await asset.originFile ?? await asset.file;
    if (source == null || !await source.exists()) {
      throw Exception('视频读取失败');
    }
    final length = await source.length();
    final oriented = asset.orientatedSize;
    final width = oriented.width.round();
    final height = oriented.height.round();
    ChatSendLog.d('视频原片 ${source.path} bytes=$length ${width}x$height');
    if (length <= 0) {
      throw Exception('视频读取失败');
    }

    final prepared = await VideoUploadPrepare.prepare(
      source: source,
      width: width,
      height: height,
    );
    if (prepared.path == source.path) {
      final target = _retarget(destination, path.extension(source.path));
      ChatSendLog.d('使用原片 -> ${target.path}');
      return _copyKeep(source, target);
    }
    final output = await _place(prepared, destination);
    ChatSendLog.d('视频压缩完成 ${output.path} bytes=${await output.length()}');
    return output;
  }

  /// 导出 Live 配对视频，强制压成 H.264，再放到 [destination]。
  static Future<File> prepareLive({
    required AssetEntity asset,
    required File destination,
  }) async {
    final prepared = await LivePhotoExport.compressedPairedVideo(asset: asset);
    final output = await _place(prepared, destination);
    ChatSendLog.d('实况视频压缩完成 ${output.path} bytes=${await output.length()}');
    return output;
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
