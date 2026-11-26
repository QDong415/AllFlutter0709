import 'dart:io';
import 'dart:typed_data';

import 'package:all_flutter0709/shared/media/preview_save_source.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

/// 大图预览长按保存：底部菜单与写入相册逻辑集中在此。
class ImagePreviewSaveActions {
  ImagePreviewSaveActions._();

  static final Dio _dio = Dio();

  /// 弹出「保存图片 / 取消」，并在确认后写入系统相册。
  static Future<void> showSaveSheet(
    BuildContext context, {
    required PreviewSaveSource saveSource,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      barrierColor: Colors.transparent,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Center(
                  child: Text(
                    '保存图片',
                    style: TextStyle(color: Color(0xFF111111), fontSize: 16),
                  ),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  if (!context.mounted) {
                    return;
                  }
                  await saveToGallery(context, saveSource);
                },
              ),
              const Divider(height: 1, color: Color(0xFFE5E5E5)),
              ListTile(
                title: const Center(
                  child: Text(
                    '取消',
                    style: TextStyle(color: Color(0xFF666666), fontSize: 16),
                  ),
                ),
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 弹出「保存视频 / 取消」，并在确认后写入系统相册。
  static Future<void> showSaveVideoSheet(
    BuildContext context, {
    required PreviewSaveSource saveSource,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      barrierColor: Colors.transparent,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Center(
                  child: Text(
                    '保存视频',
                    style: TextStyle(color: Color(0xFF111111), fontSize: 16),
                  ),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  if (!context.mounted) {
                    return;
                  }
                  await saveVideoToGallery(context, saveSource);
                },
              ),
              const Divider(height: 1, color: Color(0xFFE5E5E5)),
              ListTile(
                title: const Center(
                  child: Text(
                    '取消',
                    style: TextStyle(color: Color(0xFF666666), fontSize: 16),
                  ),
                ),
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 按来源读取或下载视频并保存到相册，失败时 Toast 提示。
  static Future<void> saveVideoToGallery(
    BuildContext context,
    PreviewSaveSource saveSource,
  ) async {
    try {
      final didSave = await _saveVideo(saveSource);
      if (!context.mounted) {
        return;
      }
      if (!didSave) {
        _showMessage(context, '视频无效');
        return;
      }
      _showMessage(context, '已保存到相册');
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      _showMessage(context, '保存失败: $e');
    }
  }

  /// 按来源读取或下载图片并保存到相册，失败时 Toast 提示。
  static Future<void> saveToGallery(
    BuildContext context,
    PreviewSaveSource saveSource,
  ) async {
    try {
      final didSave = await _save(saveSource);
      if (!context.mounted) {
        return;
      }
      if (!didSave) {
        _showMessage(context, '图片无效');
        return;
      }

      _showMessage(context, '已保存到相册');
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      _showMessage(context, '保存失败: $e');
    }
  }

  static Future<bool> _saveVideo(PreviewSaveSource saveSource) async {
    return switch (saveSource) {
      PreviewSaveFromUrl(:final url) => _saveVideoFromUrl(url),
      PreviewSaveFromLocalPath(:final path) => _saveVideoFromLocalPath(path),
    };
  }

  static Future<bool> _saveVideoFromUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    final dir = await getTemporaryDirectory();
    final name = _nameFromUrl(trimmed, prefix: 'live');
    final fileName = name.contains('.') ? name : '$name.mp4';
    final file = File('${dir.path}/$fileName');
    try {
      await _dio.download(trimmed, file.path);
      if (!await file.exists() || await file.length() <= 0) {
        return false;
      }
      await Gal.putVideo(file.path);
      return true;
    } finally {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  static Future<bool> _saveVideoFromLocalPath(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    final file = File(trimmed);
    if (!file.existsSync()) {
      return false;
    }
    await Gal.putVideo(file.path);
    return true;
  }

  static Future<bool> _save(PreviewSaveSource saveSource) async {
    return switch (saveSource) {
      PreviewSaveFromUrl(:final url) => _saveFromUrl(url),
      PreviewSaveFromLocalPath(:final path) => _saveFromLocalPath(path),
    };
  }

  static Future<bool> _saveFromUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    final response = await _dio.get<List<int>>(
      trimmed,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null || data.isEmpty) {
      return false;
    }
    await Gal.putImageBytes(
      Uint8List.fromList(data),
      name: _nameFromUrl(trimmed, prefix: 'image'),
    );
    return true;
  }

  static Future<bool> _saveFromLocalPath(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    final file = File(trimmed);
    if (!file.existsSync()) {
      return false;
    }
    await Gal.putImage(file.path);
    return true;
  }

  static String _nameFromUrl(String imageUrl, {required String prefix}) {
    final uri = Uri.tryParse(imageUrl);
    final lastSegment = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : null;
    final fileName = (lastSegment == null || lastSegment.isEmpty)
        ? '${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg'
        : lastSegment;
    return fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
  }

  static void _showMessage(BuildContext context, String message) {
    AppToast.show(context, message);
  }
}
