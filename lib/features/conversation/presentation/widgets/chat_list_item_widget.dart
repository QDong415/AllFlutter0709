import 'dart:io';
import 'dart:math' as math;

import 'package:all_flutter0709/features/conversation/presentation/models/chat_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 聊天气泡列表单项（时间 tips / 文本 / 语音 / 图片）。
class ChatListItemWidget extends StatelessWidget {
  const ChatListItemWidget({
    super.key,
    required this.item,
    this.onImageTap,
    this.onAvatarTap,
  });

  final ChatItem item;
  final ValueChanged<ImageMessage>? onImageTap;
  final ValueChanged<MessageItem>? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    if (item is TimeItem) {
      return _TimeItemWidget(item: item as TimeItem);
    }

    if (item is TextMessage) {
      final textItem = item as TextMessage;
      return _MessageRow(
        direction: textItem.direction,
        avatarUrl: textItem.avatarUrl,
        deliveryStatus: textItem.deliveryStatus,
        uploadProgress: textItem.uploadProgress,
        bubble: _TextBubble(item: textItem),
        onAvatarTap: onAvatarTap == null ? null : () => onAvatarTap!(textItem),
      );
    }

    if (item is VoiceMessage) {
      final voiceItem = item as VoiceMessage;
      return _MessageRow(
        direction: voiceItem.direction,
        avatarUrl: voiceItem.avatarUrl,
        deliveryStatus: voiceItem.deliveryStatus,
        uploadProgress: voiceItem.uploadProgress,
        bubble: _VoiceBubble(item: voiceItem),
        onAvatarTap: onAvatarTap == null ? null : () => onAvatarTap!(voiceItem),
      );
    }

    if (item is ImageMessage) {
      final imageItem = item as ImageMessage;
      return _MessageRow(
        direction: imageItem.direction,
        avatarUrl: imageItem.avatarUrl,
        deliveryStatus: imageItem.deliveryStatus,
        uploadProgress: imageItem.uploadProgress,
        bubble: _ImageBubble(
          item: imageItem,
          onTap: onImageTap == null ? null : () => onImageTap!(imageItem),
        ),
        onAvatarTap: onAvatarTap == null ? null : () => onAvatarTap!(imageItem),
      );
    }

    return const SizedBox.shrink();
  }
}

class _TimeItemWidget extends StatelessWidget {
  const _TimeItemWidget({required this.item});

  final TimeItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFDCDDDD),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            item.label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.direction,
    required this.avatarUrl,
    required this.deliveryStatus,
    required this.uploadProgress,
    required this.bubble,
    this.onAvatarTap,
  });

  final MessageDirection direction;
  final String avatarUrl;
  final MessageDeliveryStatus deliveryStatus;
  final int uploadProgress;
  final Widget bubble;
  final VoidCallback? onAvatarTap;

  bool get _isRight => direction == MessageDirection.right;

  bool get _showStatus =>
      deliveryStatus == MessageDeliveryStatus.sending ||
      deliveryStatus == MessageDeliveryStatus.failed;

  @override
  Widget build(BuildContext context) {
    // 对齐 iTopicX：头像 43、气泡与头像间距约 5；
    // 发送中/失败状态在气泡左侧（远离头像），marginRight 10。
    const avatarGap = 10.0;
    return Padding(
      padding: const EdgeInsets.only(top: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isRight) ...[
            const Spacer(),
            if (_showStatus)
              Padding(
                padding: const EdgeInsets.only(top: 12, right: 10),
                child: _MessageStatusIndicator(
                  status: deliveryStatus,
                  uploadProgress: uploadProgress,
                ),
              ),
            bubble,
            const SizedBox(width: avatarGap),
            _ChatAvatar(avatarUrl: avatarUrl, onTap: onAvatarTap),
            const SizedBox(width: 10),
          ] else ...[
            const SizedBox(width: 10),
            _ChatAvatar(avatarUrl: avatarUrl, onTap: onAvatarTap),
            const SizedBox(width: avatarGap),
            Flexible(
              child: Align(alignment: Alignment.centerLeft, child: bubble),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.avatarUrl, this.onTap});

  final String avatarUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 43,
        height: 43,
        child: avatarUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => const ColoredBox(
                  color: Color(0xFFF0F0F0),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: Color(0xFF999999),
                    size: 22,
                  ),
                ),
                errorWidget: (_, _, _) => const ColoredBox(
                  color: Color(0xFFF0F0F0),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: Color(0xFF999999),
                    size: 22,
                  ),
                ),
              )
            : const ColoredBox(
                color: Color(0xFFF0F0F0),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFF999999),
                  size: 22,
                ),
              ),
      ),
    );

    if (onTap == null) return avatar;
    return GestureDetector(onTap: onTap, child: avatar);
  }
}

class _TextBubble extends StatelessWidget {
  const _TextBubble({required this.item});

  final TextMessage item;

  bool get _isRight => item.direction == MessageDirection.right;

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final segments = item.text.split('\n');

    for (var index = 0; index < segments.length; index++) {
      final segment = segments[index];
      final isUrl =
          segment.startsWith('http://') || segment.startsWith('https://');
      spans.add(
        TextSpan(
          text: segment,
          style: TextStyle(
            color: isUrl ? const Color(0xFF3399FF) : const Color(0xFF222222),
            decoration: isUrl ? TextDecoration.underline : TextDecoration.none,
            height: 1.25,
          ),
        ),
      );
      if (index != segments.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return _BubbleFrame(
      isRight: _isRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200, minHeight: 43),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 15),
              children: spans,
            ),
          ),
        ),
      ),
    );
  }
}

class _VoiceBubble extends StatelessWidget {
  const _VoiceBubble({required this.item});

  final VoiceMessage item;

  bool get _isRight => item.direction == MessageDirection.right;

  @override
  Widget build(BuildContext context) {
    final width = math.max(82.0, math.min(168.0, 64.0 + item.seconds * 16.0));
    final icon = _isRight
        ? Icons.volume_up_rounded
        : Icons.multitrack_audio_rounded;

    return _BubbleFrame(
      isRight: _isRight,
      child: SizedBox(
        width: width,
        height: 43,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: _isRight
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: _isRight
                ? [
                    Text(
                      '${item.seconds}"',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(icon, color: const Color(0xFF222222)),
                  ]
                : [
                    Icon(icon, color: const Color(0xFF222222)),
                    const SizedBox(width: 8),
                    Text(
                      '${item.seconds}"',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

class _BubbleFrame extends StatelessWidget {
  const _BubbleFrame({required this.isRight, required this.child});

  final bool isRight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isRight ? const Color(0xFF95EC69) : Colors.white;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: child,
        ),
        Positioned(
          top: 12,
          left: isRight ? null : -5,
          right: isRight ? -5 : null,
          child: _BubbleTail(color: bubbleColor, isRight: isRight),
        ),
      ],
    );
  }
}

class _BubbleTail extends StatelessWidget {
  const _BubbleTail({required this.color, required this.isRight});

  final Color color;
  final bool isRight;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(8, 12),
      painter: _BubbleTailPainter(color: color, isRight: isRight),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter({required this.color, required this.isRight});

  final Color color;
  final bool isRight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    if (isRight) {
      path
        ..moveTo(0, 1)
        ..quadraticBezierTo(
          size.width * 0.2,
          size.height * 0.15,
          size.width,
          size.height * 0.2,
        )
        ..lineTo(size.width * 0.05, size.height)
        ..close();
    } else {
      path
        ..moveTo(size.width, 1)
        ..quadraticBezierTo(
          size.width * 0.8,
          size.height * 0.15,
          0,
          size.height * 0.2,
        )
        ..lineTo(size.width * 0.95, size.height)
        ..close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isRight != isRight;
  }
}

class _ImageBubble extends StatelessWidget {
  const _ImageBubble({required this.item, this.onTap});

  final ImageMessage item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // 对齐 iTopicX：最大边约 155dp，高度上限 150。
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

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
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
      ),
    );
  }
}

class _MessageStatusIndicator extends StatelessWidget {
  const _MessageStatusIndicator({
    required this.status,
    required this.uploadProgress,
  });

  final MessageDeliveryStatus status;
  final int uploadProgress;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageDeliveryStatus.sent:
        return const SizedBox.shrink();
      case MessageDeliveryStatus.sending:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            value: uploadProgress > 0 ? uploadProgress / 100 : null,
            strokeWidth: 1.8,
          ),
        );
      case MessageDeliveryStatus.failed:
        return const Icon(
          Icons.error_outline_rounded,
          size: 18,
          color: Color(0xFFD93025),
        );
    }
  }
}
