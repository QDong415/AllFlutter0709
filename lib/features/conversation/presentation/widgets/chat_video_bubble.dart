import 'dart:io';
import 'dart:math' as math;

import 'package:all_flutter0709/features/conversation/presentation/models/chat_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 视频气泡。只展示封面、时长和发送状态，点按播放由行壳分发。
class ChatVideoBubble extends StatelessWidget {
  const ChatVideoBubble({
    super.key,
    required this.item,
    this.isSelected = false,
  });

  final VideoMessage item;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    const maxSide = 155.0;
    const maxHeight = 150.0;
    final rawW = item.videoWidth <= 0 ? maxSide : item.videoWidth;
    final rawH = item.videoHeight <= 0 ? maxSide : item.videoHeight;
    final scale = math.min(maxSide / rawW, maxHeight / rawH);
    final width = math.max(72.0, rawW * scale);
    final height = math.max(72.0, rawH * scale);
    final sending = item.deliveryStatus == MessageDeliveryStatus.sending;
    final cover = _cover(context, width, height);

    final body = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            cover,
            if (!sending)
              Center(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Color(0x66000000),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            if (item.durationSeconds > 0)
              Positioned(
                right: 6,
                bottom: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x66000000),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    child: Text(
                      _formatDuration(item.durationSeconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            if (sending) _sendingOverlay(item.uploadProgress),
          ],
        ),
      ),
    );

    if (!isSelected) {
      return body;
    }
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Color(0x33000000), BlendMode.srcATop),
      child: body,
    );
  }

  Widget _cover(BuildContext context, double width, double height) {
    final coverPath = item.coverPath;
    final coverFile = coverPath == null ? null : File(coverPath);
    final useLocal = coverFile != null && coverFile.existsSync();
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (width * dpr).round().clamp(1, 4096);
    final cacheHeight = (height * dpr).round().clamp(1, 4096);
    if (useLocal) {
      return Image.file(
        coverFile,
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        filterQuality: FilterQuality.low,
      );
    }
    final url = item.coverUrl?.trim() ?? '';
    if (url.isEmpty) {
      return const ColoredBox(color: Color(0xFF2C2C2C));
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => const ColoredBox(color: Color(0xFF2C2C2C)),
      errorWidget: (_, _, _) => const ColoredBox(color: Color(0xFF2C2C2C)),
    );
  }

  Widget _sendingOverlay(int progress) {
    final showPercent = progress > 0;
    return ColoredBox(
      color: const Color(0x55000000),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                value: showPercent ? progress / 100 : null,
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            ),
            if (showPercent) ...[
              const SizedBox(height: 8),
              Text(
                '${progress.clamp(0, 99)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final minutes = safe ~/ 60;
    final remain = safe % 60;
    return '$minutes:${remain.toString().padLeft(2, '0')}';
  }
}
