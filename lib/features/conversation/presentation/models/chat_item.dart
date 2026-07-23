sealed class ChatItem {
  const ChatItem();
}

final class TimeItem extends ChatItem {
  const TimeItem({required this.label});

  final String label;
}

enum MessageDirection { left, right }

enum MessageDeliveryStatus { sent, sending, failed }

sealed class MessageItem extends ChatItem {
  const MessageItem({
    required this.direction,
    required this.avatarUrl,
    this.deliveryStatus = MessageDeliveryStatus.sent,
    this.uploadProgress = 0,
  });

  final MessageDirection direction;
  final String avatarUrl;
  final MessageDeliveryStatus deliveryStatus;
  final int uploadProgress;
}

final class TextMessage extends MessageItem {
  const TextMessage({
    required super.direction,
    required super.avatarUrl,
    super.deliveryStatus,
    required this.text,
  });

  final String text;
}

final class VoiceMessage extends MessageItem {
  const VoiceMessage({
    required super.direction,
    required super.avatarUrl,
    super.deliveryStatus,
    required this.seconds,
    this.audioPath,
  });

  final int seconds;
  final String? audioPath;
}

final class ImageMessage extends MessageItem {
  const ImageMessage({
    required super.direction,
    required super.avatarUrl,
    super.deliveryStatus,
    super.uploadProgress,
    this.imageUrl,
    this.imagePath,
    required this.imageWidth,
    required this.imageHeight,
  }) : assert(imageUrl != null || imagePath != null);

  final String? imageUrl;
  final String? imagePath;
  final double imageWidth;
  final double imageHeight;
}
