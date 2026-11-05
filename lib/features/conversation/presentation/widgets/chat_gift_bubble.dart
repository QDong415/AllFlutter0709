import 'package:all_flutter0709/features/conversation/presentation/models/chat_item.dart';
import 'package:all_flutter0709/features/gift/presentation/gift_count_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 聊天礼物：140 的礼物图，旁边是数量切图。没有文字气泡。
///
/// 自己发出的数量在图左边，且乘号在数字右边；对方发来的数量在图右边，乘号在左边。
class ChatGiftBubble extends StatelessWidget {
  const ChatGiftBubble({
    super.key,
    required this.item,
    this.isSelected = false,
  });

  final GiftMessage item;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final isRight = item.direction == MessageDirection.right;
    final image = SizedBox(
      width: 140,
      height: 140,
      child: item.pictureUrl.isEmpty
          ? const Icon(Icons.card_giftcard, size: 72, color: Color(0xFFE85D75))
          : CachedNetworkImage(
              imageUrl: item.pictureUrl,
              fit: BoxFit.contain,
              errorWidget: (context, url, error) => const Icon(
                Icons.card_giftcard,
                size: 72,
                color: Color(0xFFE85D75),
              ),
            ),
    );
    final count = GiftCountBadge(
      count: item.count,
      markOnRight: isRight,
    );
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: isRight
          ? [count, const SizedBox(width: 12), image]
          : [image, const SizedBox(width: 12), count],
    );
    if (!isSelected) {
      return row;
    }
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Color(0x33000000), BlendMode.srcATop),
      child: row,
    );
  }
}
