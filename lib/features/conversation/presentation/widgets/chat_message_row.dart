import 'package:all_flutter0709/features/conversation/presentation/models/chat_item.dart';
import 'package:all_flutter0709/features/conversation/presentation/models/chat_message_interaction.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_bubble_metrics.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 消息行壳：头像、左右对齐、发送状态；气泡点按 / 长按统一在这里收。
class ChatMessageRow extends StatelessWidget {
  const ChatMessageRow({
    super.key,
    required this.item,
    required this.bubble,
    this.actions = ChatMessageActions.empty,
  });

  final MessageItem item;
  final Widget bubble;
  final ChatMessageActions actions;

  bool get _isRight => item.isRight;

  bool get _showStatus =>
      item.deliveryStatus == MessageDeliveryStatus.sending ||
      item.deliveryStatus == MessageDeliveryStatus.failed;

  @override
  Widget build(BuildContext context) {
    final bubbleChild = _BubbleGesture(
      item: item,
      onTap: actions.onMessageTap,
      onLongPress: actions.onMessageLongPress,
      child: bubble,
    );

    return Padding(
      padding: const EdgeInsets.only(top: ChatBubbleMetrics.messageSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isRight) ...[
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_showStatus)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, right: 10),
                        child: _MessageStatusIndicator(
                          status: item.deliveryStatus,
                          uploadProgress: item.uploadProgress,
                        ),
                      ),
                    Flexible(child: bubbleChild),
                  ],
                ),
              ),
            ),
            const SizedBox(width: ChatBubbleMetrics.avatarGap),
            _ChatAvatar(
              avatarUrl: item.avatarUrl,
              onTap: actions.onAvatarTap == null
                  ? null
                  : () => actions.onAvatarTap!(item),
            ),
            const SizedBox(width: ChatBubbleMetrics.screenPadding),
          ] else ...[
            const SizedBox(width: ChatBubbleMetrics.screenPadding),
            _ChatAvatar(
              avatarUrl: item.avatarUrl,
              onTap: actions.onAvatarTap == null
                  ? null
                  : () => actions.onAvatarTap!(item),
            ),
            const SizedBox(width: ChatBubbleMetrics.avatarGap),
            Flexible(
              child: Align(alignment: Alignment.centerLeft, child: bubbleChild),
            ),
            const SizedBox(width: ChatBubbleMetrics.oppositeReserve),
          ],
        ],
      ),
    );
  }
}

/// 把点按 / 长按挂在气泡上，长按回传屏幕矩形供菜单定位。
class _BubbleGesture extends StatelessWidget {
  const _BubbleGesture({
    required this.item,
    required this.child,
    this.onTap,
    this.onLongPress,
  });

  final MessageItem item;
  final Widget child;
  final ValueChanged<MessageItem>? onTap;
  final ValueChanged<ChatBubbleLongPressDetails>? onLongPress;

  @override
  Widget build(BuildContext context) {
    if (onTap == null && onLongPress == null) {
      return child;
    }

    return Builder(
      builder: (gestureContext) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap == null ? null : () => onTap!(item),
          onLongPressStart: onLongPress == null
              ? null
              : (details) {
                  HapticFeedback.mediumImpact();
                  final box = gestureContext.findRenderObject() as RenderBox?;
                  final origin = box?.localToGlobal(Offset.zero);
                  final bubbleRect = box == null || origin == null
                      ? Rect.fromLTWH(
                          details.globalPosition.dx,
                          details.globalPosition.dy,
                          0,
                          0,
                        )
                      : origin & box.size;
                  onLongPress!(
                    ChatBubbleLongPressDetails(
                      item: item,
                      globalPosition: details.globalPosition,
                      bubbleRect: bubbleRect,
                    ),
                  );
                },
          child: child,
        );
      },
    );
  }
}

/// 聊天页头像；禁用 CachedNetworkImage 默认淡入，避免进入会话时头像渐变出现。
class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.avatarUrl, this.onTap});

  final String avatarUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: ChatBubbleMetrics.avatarSize,
        height: ChatBubbleMetrics.avatarSize,
        child: avatarUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                placeholderFadeInDuration: Duration.zero,
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

    if (onTap == null) {
      return avatar;
    }
    return GestureDetector(onTap: onTap, child: avatar);
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
