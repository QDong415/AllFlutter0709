import 'dart:io';

import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/features/conversation/presentation/helpers/chat_live_picker_delegate.dart';
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

/// 选中的 Live 图，并且勾了「实况」。按带短视频的图片消息发送。
class ChatAlbumLiveImage extends ChatAlbumPick {
  const ChatAlbumLiveImage(this.asset);

  final AssetEntity asset;
}

/// 聊天和评论共用的相册。图片和视频在同一个网格里，只能选 1 个。
class ChatAlbumPickHelper {
  const ChatAlbumPickHelper();

  /// 打开相册。取消或没有权限时返回 null。
  ///
  /// 选中 Live 时底部有「实况」勾选，默认不勾。勾上后返回 [ChatAlbumLiveImage]。
  Future<ChatAlbumPick?> pick(BuildContext context) async {
    final PermissionState permission;
    try {
      permission = await AssetPicker.permissionCheck(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.common,
            mediaLocation: false,
          ),
        ),
      );
    } on StateError {
      return null;
    }
    if (!context.mounted) {
      return null;
    }

    final provider = DefaultAssetPickerProvider(
      maxAssets: 1,
      requestType: RequestType.common,
    );
    final delegate = ChatLivePickerDelegate(
      provider: provider,
      initialPermission: permission,
      themeColor: AppColors.link,
      textDelegate: const AssetPickerTextDelegate(),
      locale: Localizations.maybeLocaleOf(context),
    );
    final List<AssetEntity>? assetList;
    var sendLive = false;
    try {
      if (!context.mounted) {
        return null;
      }
      assetList = await AssetPicker.pickAssetsWithDelegate(
        context,
        delegate: delegate,
      );
      sendLive = delegate.sendLive.value;
    } on StateError {
      return null;
    } finally {
      delegate.sendLive.dispose();
    }
    if (assetList == null || assetList.isEmpty) {
      return null;
    }
    final asset = assetList.first;
    if (sendLive && asset.isLivePhoto) {
      return ChatAlbumLiveImage(asset);
    }
    if (asset.type == AssetType.video) {
      return ChatAlbumVideo(asset);
    }
    if (asset.type != AssetType.image) {
      return null;
    }
    final file = await imageFileOf(asset);
    if (file == null) {
      return null;
    }
    return ChatAlbumImage(file);
  }

  /// 取出静图文件。HEIC 先要系统导出的 JPEG，iOS 再压到接近原来系统选择器的质量。
  Future<File?> imageFileOf(AssetEntity asset) async {
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
