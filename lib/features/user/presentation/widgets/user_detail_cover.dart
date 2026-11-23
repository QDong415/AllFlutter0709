import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:all_flutter0709/features/user/data/profile_cover_catalog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 个人主页封面。铺满父组件给出的正方形区域。
///
/// 平时只露出中间一段，下拉时由外层把整张图往下带，露出上下被挡住的部分。
class UserDetailCover extends StatelessWidget {
  const UserDetailCover({super.key, required this.cover});

  final String cover;

  static const defaultAsset = ProfileCoverCatalog.defaultAsset;

  @override
  Widget build(BuildContext context) {
    final localAsset = ProfileCoverCatalog.assetFor(cover);
    final coverUrl = ValueUtil.getQiniuUrlByFileName(
      cover,
      limitPx: 1080,
      max: true,
    );
    if (localAsset != null) {
      return Image.asset(
        localAsset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
      );
    }
    if (coverUrl == null || coverUrl.isEmpty) {
      return Image.asset(
        defaultAsset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return CachedNetworkImage(
      imageUrl: coverUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, _) => Image.asset(
        defaultAsset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
      errorWidget: (_, _, _) => Image.asset(
        defaultAsset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}
