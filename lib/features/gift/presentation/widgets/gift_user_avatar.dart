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
            ? const ColoredBox(
                color: Color(0xFFE8E8ED),
                child: Icon(Icons.person, color: Color(0xFFB0B0B6)),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const ColoredBox(
                  color: Color(0xFFE8E8ED),
                  child: Icon(Icons.person, color: Color(0xFFB0B0B6)),
                ),
              ),
      ),
    );
  }
}
