import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:video_compress/video_compress.dart';

/// 压缩被取消，调用方应停止上传。
class VideoPrepareCancelled implements Exception {
  /// 创建取消标记。
  const VideoPrepareCancelled();
}

/// 聊天和动态发视频前的本地压缩。
///
/// 长边大于 1280 时压成 720p。安卓目标码率约 5.4Mbps；
/// iPhone 用同样码率封住导出文件大小。宽高未知时也压缩。
/// 压缩失败且原片不超过 100MB 时改发原片。
class VideoUploadPrepare {
  VideoUploadPrepare._();

  /// 压缩失败时，原片超过这个体积就不再发送。
  static const maxOriginalBytes = 100 * 1024 * 1024;

  /// 长边不超过这个值就直接传原片。
  static const maxLongEdge = 1280;

  static Future<void> _queue = Future<void>.value();
  static Object? _activeOwner;

  /// 长边超过 [maxLongEdge] 才需要压缩。宽或高未知时也压缩。
  static bool needsCompress({required int width, required int height}) {
    if (width <= 0 || height <= 0) {
      return true;
    }
    final longEdge = width > height ? width : height;
    return longEdge > maxLongEdge;
  }

  /// 压缩失败后是否可以改发原片。
  static bool canSendOriginal(int length) {
    return length > 0 && length <= maxOriginalBytes;
  }

  /// 返回实际上传的文件。不需要压缩或压缩失败且允许发原片时，返回 [source]。
  ///
  /// [force] 为 true 时忽略长边，一律转成 720p H.264。Live 配对视频用这个，
  /// 避免 1080p 的 HEVC 原片直接上传。
  /// [allowOriginalFallback] 为 false 时，压缩失败不再改发原片。
  /// [owner] 用来让取消只打断这一次压缩，避免误停队列里另一条正在压的视频。
  static Future<File> prepare({
    required File source,
    required int width,
    required int height,
    Object? owner,
    bool Function()? isCancelled,
    bool force = false,
    bool allowOriginalFallback = true,
  }) {
    if (!force && !needsCompress(width: width, height: height)) {
      return Future<File>.value(source);
    }
    return _enqueue(
      () => _prepare(
        source: source,
        owner: owner,
        isCancelled: isCancelled,
        allowOriginalFallback: allowOriginalFallback,
      ),
    );
  }

  /// 只取消 [owner] 正在进行的那一次压缩。
  static Future<void> cancel(Object owner) async {
    if (_activeOwner == null || !identical(_activeOwner, owner)) {
      return;
    }
    try {
      await VideoCompress.cancelCompression();
    } catch (_) {}
  }

  static Future<T> _enqueue<T>(Future<T> Function() job) {
    final run = _queue.then((_) => job());
    _queue = run.then((_) {}, onError: (_) {});
    return run;
  }

  static Future<File> _prepare({
    required File source,
    required Object? owner,
    required bool Function()? isCancelled,
    required bool allowOriginalFallback,
  }) async {
    if (isCancelled?.call() == true) {
      throw const VideoPrepareCancelled();
    }
    final length = await source.length();
    if (length <= 0) {
      throw Exception('视频读取失败');
    }
    _activeOwner = owner;
    try {
      if (isCancelled?.call() == true) {
        throw const VideoPrepareCancelled();
      }
      final compressed = await _compress(source);
      if (isCancelled?.call() == true) {
        throw const VideoPrepareCancelled();
      }
      return compressed;
    } catch (error) {
      if (error is VideoPrepareCancelled || isCancelled?.call() == true) {
        throw const VideoPrepareCancelled();
      }
      try {
        await VideoCompress.cancelCompression();
      } catch (_) {}
      if (isCancelled?.call() == true) {
        throw const VideoPrepareCancelled();
      }
      if (!allowOriginalFallback) {
        throw Exception('视频压缩失败');
      }
      if (!canSendOriginal(length)) {
        throw Exception('视频太大，发送失败');
      }
      debugPrint('[VideoUpload] 压缩失败，改发原片: $error');
      return source;
    } finally {
      if (identical(_activeOwner, owner)) {
        _activeOwner = null;
      }
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
}
