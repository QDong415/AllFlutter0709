import 'dart:io';

import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/features/conversation/presentation/helpers/chat_video_prepare.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

/// 聊天相册的一次选择结果。
sealed class ChatAlbumPick {
  const ChatAlbumPick();
}

/// 选中的图片文件。
class ChatAlbumImage extends ChatAlbumPick {
  const ChatAlbumImage(this.file);

  final File file;
}

/// 选中的视频资源。原片导出和压缩放到气泡出现之后。
class ChatAlbumVideo extends ChatAlbumPick {
  const ChatAlbumVideo(this.asset);

  final AssetEntity asset;
}

/// 聊天「图片」入口的相册。图片和视频在同一个网格里，只能选 1 个。
class ChatAlbumPickHelper {
  const ChatAlbumPickHelper();

  /// 打开相册。取消或没有权限时返回 null。
  Future<ChatAlbumPick?> pick(BuildContext context) async {
    final List<AssetEntity>? assetList;
    try {
      assetList = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
          maxAssets: 1,
          requestType: RequestType.common,
          themeColor: AppColors.link,
          textDelegate: const AssetPickerTextDelegate(),
          selectPredicate: _allowSelect,
        ),
      );
    } on StateError {
      return null;
    }
    if (assetList == null || assetList.isEmpty) {
      return null;
    }
    final asset = assetList.first;
    if (asset.type == AssetType.video) {
      return ChatAlbumVideo(asset);
    }
    if (asset.type != AssetType.image) {
      return null;
    }
    final file = await _imageFileOf(asset);
    if (file == null) {
      return null;
    }
    return ChatAlbumImage(file);
  }

  Future<bool> _allowSelect(
    BuildContext context,
    AssetEntity asset,
    bool isSelected,
  ) async {
    if (isSelected || asset.type != AssetType.video) {
      return true;
    }
    if (asset.duration <= ChatVideoPrepare.maxDurationSeconds) {
      return true;
    }
    AppToast.show(context, '视频不能超过 5 分钟');
    return false;
  }

  /// HEIC 转成系统导出的 JPEG。iOS 再压到接近原来系统选择器的质量。
  Future<File?> _imageFileOf(AssetEntity asset) async {
    final origin = await asset.originFile;
    final lower = origin?.path.toLowerCase() ?? '';
    final File? file;
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      file = await asset.file ?? origin;
    } else {
      file = origin ?? await asset.file;
    }
    if (file == null || !Platform.isIOS) {
      return file;
    }
    final pathLower = file.path.toLowerCase();
    if (pathLower.endsWith('.gif')) {
      return file;
    }
    return _compressIosImage(file);
  }

  Future<File> _compressIosImage(File file) async {
    try {
      final directory = await getTemporaryDirectory();
      final target =
          '${directory.path}${Platform.pathSeparator}chat_pick_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        target,
        quality: 92,
        format: CompressFormat.jpeg,
      );
      if (compressed == null) {
        return file;
      }
      return File(compressed.path);
    } catch (_) {
      return file;
    }
  }
}
