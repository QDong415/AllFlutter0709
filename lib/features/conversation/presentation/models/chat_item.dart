/// 聊天列表展示项：时间 tips 或一条消息。
sealed class ChatItem {
  const ChatItem();
}

/// 会话时间分隔 tips。
final class TimeItem extends ChatItem {
  const TimeItem({required this.label});

  final String label;
}

/// 气泡左右方向。
enum MessageDirection { left, right }

/// 消息发送状态。
enum MessageDeliveryStatus { sent, sending, failed }

/// 聊天气泡消息基类；[id] 用于点按、长按、播放互斥、删除定位。
sealed class MessageItem extends ChatItem {
  const MessageItem({
    required this.id,
    required this.msgId,
    required this.clientMessageId,
    required this.direction,
    required this.avatarUrl,
    this.deliveryStatus = MessageDeliveryStatus.sent,
    this.uploadProgress = 0,
  });

  /// 展示层稳定 id：优先 [clientMessageId]，否则 `msg_{msgId}`。
  final String id;

  /// 服务端消息 id；发送中可能为 0。
  final int msgId;

  /// 客户端消息 id；本地发送链路用它更新状态。
  final String clientMessageId;

  final MessageDirection direction;
  final String avatarUrl;
  final MessageDeliveryStatus deliveryStatus;
  final int uploadProgress;

  /// 是否为右侧己方气泡。
  bool get isRight => direction == MessageDirection.right;

  @override
  bool operator ==(Object other) => other is MessageItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// 文本气泡。
final class TextMessage extends MessageItem {
  const TextMessage({
    required super.id,
    required super.msgId,
    required super.clientMessageId,
    required super.direction,
    required super.avatarUrl,
    super.deliveryStatus,
    required this.text,
  });

  final String text;
}

/// 语音条气泡。
final class VoiceMessage extends MessageItem {
  const VoiceMessage({
    required super.id,
    required super.msgId,
    required super.clientMessageId,
    required super.direction,
    required super.avatarUrl,
    super.deliveryStatus,
    required this.seconds,
    this.audioPath,
    this.audioUrl,
    this.hadPlay = false,
  });

  final int seconds;
  final String? audioPath;
  final String? audioUrl;
  final bool hadPlay;

  /// 是否已有可播放的本地文件或远端地址。
  bool get hasAudio {
    final path = audioPath?.trim() ?? '';
    final url = audioUrl?.trim() ?? '';
    return path.isNotEmpty || url.isNotEmpty;
  }
}

/// 图片气泡。
final class ImageMessage extends MessageItem {
  const ImageMessage({
    required super.id,
    required super.msgId,
    required super.clientMessageId,
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
