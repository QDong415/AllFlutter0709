import 'dart:io';

import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/features/topic/data/models/topic_submit_media_model.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

/// 发布页底部菜单动作。
enum TopicMediaPickAction { pickImages, pickVideo }

/// 发布动态选图 / 选视频；图最多 9 张，与视频互斥。
class TopicMediaPickHelper {
  const TopicMediaPickHelper();

  static const int maxImageCount = 9;

  /// 剩余可再选的图片数量。
  int remainImageCount(List<TopicSubmitMediaModel> mediaList) {
    if (mediaList.any((item) => item.isVideo)) {
      return 0;
    }
    return maxImageCount - mediaList.length;
  }

  /// 是否还能继续添加媒体。
  bool canAddMore(List<TopicSubmitMediaModel> mediaList) {
    return remainImageCount(mediaList) > 0;
  }

  /// 打开相册多选图片。
  Future<List<TopicSubmitMediaModel>> pickImages({
    required BuildContext context,
    required int remainCount,
  }) async {
    if (remainCount <= 0) {
      return const <TopicSubmitMediaModel>[];
    }
    final assetList = await AssetPicker.pickAssets(
      context,
      pickerConfig: _pickerConfig(
        maxAssets: remainCount,
        requestType: RequestType.image,
      ),
    );
    if (assetList == null || assetList.isEmpty) {
      return const <TopicSubmitMediaModel>[];
    }

    final mediaList = <TopicSubmitMediaModel>[];
    for (final asset in assetList.take(remainCount)) {
      final file = await _fileOf(asset);
      if (file == null) {
        continue;
      }
      mediaList.add(TopicSubmitMediaModel(file: file, isVideo: false));
    }
    return mediaList;
  }

  /// 打开相册选择 1 个视频。
  Future<TopicSubmitMediaModel?> pickVideo({
    required BuildContext context,
  }) async {
    final assetList = await AssetPicker.pickAssets(
      context,
      pickerConfig: _pickerConfig(
        maxAssets: 1,
        requestType: RequestType.video,
      ),
    );
    if (assetList == null || assetList.isEmpty) {
      return null;
    }
    final asset = assetList.first;
    final file = await _fileOf(asset);
    if (file == null) {
      return null;
    }
    return TopicSubmitMediaModel(
      file: file,
      isVideo: true,
      duration: Duration(seconds: asset.duration),
    );
  }

  AssetPickerConfig _pickerConfig({
    required int maxAssets,
    required RequestType requestType,
  }) {
    return AssetPickerConfig(
      maxAssets: maxAssets,
      requestType: requestType,
      themeColor: AppColors.link,
      textDelegate: const AssetPickerTextDelegate(),
    );
  }

  Future<File?> _fileOf(AssetEntity asset) async {
    return await asset.originFile ?? await asset.file;
  }
}
