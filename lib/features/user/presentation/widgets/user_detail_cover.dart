import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 个人主页封面；支持下拉放大。
class UserDetailCover extends StatelessWidget {
  const UserDetailCover({
    super.key,
    required this.cover,
    required this.height,
    this.stretchOffset = 0,
  });

  final String cover;
  final double height;
  final double stretchOffset;

  static const defaultAsset = 'assets/icons/user/profile_cover_default.png';

  @override
  Widget build(BuildContext context) {
    final coverUrl = ValueUtil.getQiniuUrlByFileName(
      cover,
      limitPx: 750,
      max: true,
    );
    final totalHeight = height + stretchOffset;
    final scale = stretchOffset > 0 ? (totalHeight / height) : 1.0;

    return SizedBox(
      height: totalHeight,
      width: double.infinity,
      child: ClipRect(
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.bottomCenter,
          child: coverUrl == null || coverUrl.isEmpty
              ? Image.asset(defaultAsset, fit: BoxFit.cover)
              : CachedNetworkImage(
                  imageUrl: coverUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: totalHeight,
                  placeholder: (_, _) => Image.asset(
                    defaultAsset,
                    fit: BoxFit.cover,
                  ),
                  errorWidget: (_, _, _) => Image.asset(
                    defaultAsset,
                    fit: BoxFit.cover,
                  ),
                ),
        ),
      ),
    );
  }
}
