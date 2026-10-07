import 'dart:io';

import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

/// Android 应用内相册选图。
///
/// 系统 `ACTION_GET_CONTENT` 在国产手机上会打开「选择文件」。
/// 这里改成相册网格，和发动态选图一致。
class AlbumImagePickHelper {
  const AlbumImagePickHelper();

  /// 从相册选一张图片；取消或没有相册权限时返回 null。
  Future<File?> pickImage({required BuildContext context}) async {
    final List<AssetEntity>? assetList;
    try {
      assetList = await AssetPicker.pickAssets(
        context,
        pickerConfig: const AssetPickerConfig(
          maxAssets: 1,
          requestType: RequestType.image,
          themeColor: AppColors.link,
          textDelegate: AssetPickerTextDelegate(),
        ),
      );
    } on StateError {
      return null;
    }
    if (assetList == null || assetList.isEmpty) {
      return null;
    }
    final asset = assetList.first;
    return await asset.originFile ?? await asset.file;
  }
}
