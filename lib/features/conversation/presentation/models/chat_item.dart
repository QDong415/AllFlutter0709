/// 聊天列表展示项：时间 tips 或一条消息。
sealed class ChatItem {
  const ChatItem();
}

/// 会话时间分隔 tips。
final class TimeItem extends ChatItem {
  const TimeItem({required this.label});

  final String label;
}

/// 撤回后的居中提示。它是一条真实消息，不是按时间间隔算出来的 [TimeItem]。
final class RecallItem extends ChatItem {
  const RecallItem({required this.id, required this.label});

  final String id;
  final String label;
}

/// 服务端下发的居中 tips，例如 AI 生图扣费提醒。
final class TipsItem extends ChatItem {
  const TipsItem({required this.id, required this.label});

  final String id;
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
    required this.createTimeSeconds,
    this.deliveryStatus = MessageDeliveryStatus.sent,
    this.uploadProgress = 0,
  });

  /// 展示层稳定 id：优先 [clientMessageId]，否则 `msg_{msgId}`。
  final String id;

  /// 服务端消息 id；发送中可能为 0。
  final int msgId;

  /// 发送方本地生成的消息 id。同一用户下不重复即可。
  final int clientMessageId;

  final MessageDirection direction;
  final String avatarUrl;

  /// 消息创建时间，秒。用来判断还能不能撤回。
  final int createTimeSeconds;
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
    required super.createTimeSeconds,
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
    required super.createTimeSeconds,
    super.deliveryStatus,
    super.uploadProgress,
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

/// 礼物气泡。
final class GiftMessage extends MessageItem {
  const GiftMessage({
    required super.id,
    required super.msgId,
    required super.clientMessageId,
    required super.direction,
    required super.avatarUrl,
    required super.createTimeSeconds,
    super.deliveryStatus,
    required this.title,
    required this.pictureUrl,
    required this.count,
  });

  final String title;
  final String pictureUrl;
  final int count;
}

/// 图片气泡。
final class ImageMessage extends MessageItem {
  const ImageMessage({
    required super.id,
    required super.msgId,
    required super.clientMessageId,
    required super.direction,
    required super.avatarUrl,
    required super.createTimeSeconds,
    super.deliveryStatus,
    super.uploadProgress,
    this.imageUrl,
    this.imagePath,
    this.liveVideoUrl,
    this.liveVideoPath,
    required this.imageWidth,
    required this.imageHeight,
  }) : assert(imageUrl != null || imagePath != null);

  final String? imageUrl;
  final String? imagePath;

  /// 实况短视频远端地址。空表示这张图没有实况。
  final String? liveVideoUrl;

  /// 发送方沙盒里的实况短视频。接收方通常为空，改播 [liveVideoUrl]。
  final String? liveVideoPath;
  final double imageWidth;
  final double imageHeight;

  bool get hasLive {
    final remote = liveVideoUrl?.trim() ?? '';
    final local = liveVideoPath?.trim() ?? '';
    return remote.isNotEmpty || local.isNotEmpty;
  }

  /// 本地文件已经写好，或消息已发出且有远端地址时可以打开画廊。
  bool get canPlayLive {
    if (!hasLive) {
      return false;
    }
    if ((liveVideoPath?.trim() ?? '').isNotEmpty) {
      return true;
    }
    return deliveryStatus == MessageDeliveryStatus.sent &&
        (liveVideoUrl?.trim() ?? '').isNotEmpty;
  }
}

/// 视频气泡。封面可空，点开用本地文件或远端地址播放。
final class VideoMessage extends MessageItem {
  const VideoMessage({
    required super.id,
    required super.msgId,
    required super.clientMessageId,
    required super.direction,
    required super.avatarUrl,
    required super.createTimeSeconds,
    super.deliveryStatus,
    super.uploadProgress,
    this.coverUrl,
    this.coverPath,
    this.videoUrl,
    this.videoPath,
    required this.videoWidth,
    required this.videoHeight,
    required this.durationSeconds,
  });

  final String? coverUrl;
  final String? coverPath;
  final String? videoUrl;
  final String? videoPath;
  final double videoWidth;
  final double videoHeight;
  final int durationSeconds;
}

/// 动态分享卡片气泡。
final class TopicMessage extends MessageItem {
  const TopicMessage({
    required super.id,
    required super.msgId,
    required super.clientMessageId,
    required super.direction,
    required super.avatarUrl,
    required super.createTimeSeconds,
    super.deliveryStatus,
    required this.tid,
    required this.content,
    required this.pictureUrl,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.hasVideo,
  });

  final String tid;
  final String content;
  final String pictureUrl;
  final String authorName;
  final String authorAvatarUrl;
  final bool hasVideo;
}
