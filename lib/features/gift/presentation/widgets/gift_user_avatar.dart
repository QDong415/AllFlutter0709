import 'package:all_flutter0709/app/theme/app_palette.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 礼物墙 / 榜单 / 送礼流水共用的圆形头像。
class GiftUserAvatar extends StatelessWidget {
  const GiftUserAvatar({super.key, required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim() ?? '';
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl.isEmpty
            ? ColoredBox(
                color: context.palette.pressed,
                child: Icon(Icons.person, color: context.palette.secondaryText),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => ColoredBox(
                  color: context.palette.pressed,
                  child: Icon(
                    Icons.person,
                    color: context.palette.secondaryText,
                  ),
                ),
              ),
      ),
    );
  }
}
