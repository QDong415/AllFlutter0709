import 'dart:io';
import 'dart:math' as math;

import 'package:all_flutter0709/features/conversation/presentation/models/chat_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 图片气泡；点按预览由行壳 [ChatMessageActions.onMessageTap] 统一分发。
class ChatImageBubble extends StatelessWidget {
  const ChatImageBubble({
    super.key,
    required this.item,
    this.isSelected = false,
  });

  final ImageMessage item;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    // 最大边约 155dp，高度上限 150。
    const maxSide = 155.0;
    const maxHeight = 150.0;
    final rawW = item.imageWidth <= 0 ? maxSide : item.imageWidth;
    final rawH = item.imageHeight <= 0 ? maxSide : item.imageHeight;
    final scale = math.min(maxSide / rawW, maxHeight / rawH);
    final width = math.max(55.0, rawW * scale);
    final height = math.max(55.0, rawH * scale);

    final imageWidget = item.imagePath != null
        ? Image.file(File(item.imagePath!), fit: BoxFit.cover)
        : CachedNetworkImage(
            imageUrl: item.imageUrl!,
            fit: BoxFit.cover,
            placeholder: (_, _) => const ColoredBox(
              color: Color(0xFFF1F1F1),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (_, _, _) => const ColoredBox(
              color: Color(0xFFF1F1F1),
              child: Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Color(0xFFB0B0B0),
                ),
              ),
            ),
          );

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        children: [
          SizedBox(width: width, height: height, child: imageWidget),
          if (item.deliveryStatus == MessageDeliveryStatus.sending)
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Color(0x55000000)),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          value: item.uploadProgress <= 0
                              ? null
                              : item.uploadProgress / 100,
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${item.uploadProgress.clamp(0, 99)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (!isSelected) {
      return image;
    }
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Color(0x33000000), BlendMode.srcATop),
      child: image,
    );
  }
}
