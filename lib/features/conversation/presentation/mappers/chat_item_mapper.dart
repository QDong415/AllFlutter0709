import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';
import 'package:all_flutter0709/features/conversation/presentation/models/chat_item.dart';
import 'package:intl/intl.dart';

List<ChatItem> buildChatItems(List<ConversationMessage> messages) {
  final items = <ChatItem>[];
  ConversationMessage? previous;

  for (final message in messages) {
    if (previous == null ||
        message.createTimeSeconds - previous.createTimeSeconds > 5 * 60) {
      items.add(
        TimeItem(label: DateFormat('HH:mm').format(message.createTime)),
      );
    }
    items.add(_mapMessage(message));
    previous = message;
  }

  return items;
}

ChatItem _mapMessage(ConversationMessage message) {
  final direction = message.isSender
      ? MessageDirection.right
      : MessageDirection.left;
  final avatarUrl = message.avatarUrl;
  final deliveryStatus = switch (message.status) {
    ConversationMessageStatus.sending => MessageDeliveryStatus.sending,
    ConversationMessageStatus.failed => MessageDeliveryStatus.failed,
    ConversationMessageStatus.sent => MessageDeliveryStatus.sent,
  };

  switch (message.messageType) {
    case ConversationMessageType.image:
      final imageSize = message.imageSize;
      return ImageMessage(
        direction: direction,
        avatarUrl: avatarUrl,
        deliveryStatus: deliveryStatus,
        uploadProgress: message.uploadProgress,
        imageUrl: message.localFilePath.isEmpty ? message.imageUrl : null,
        imagePath: message.localFilePath.isEmpty ? null : message.localFilePath,
        imageWidth: imageSize['width']!.toDouble(),
        imageHeight: imageSize['height']!.toDouble(),
      );
    case ConversationMessageType.voice:
      return VoiceMessage(
        direction: direction,
        avatarUrl: avatarUrl,
        deliveryStatus: deliveryStatus,
        seconds: 1,
        audioPath: message.localFilePath.isEmpty ? null : message.localFilePath,
      );
    case ConversationMessageType.callAudio:
      return TextMessage(
        direction: direction,
        avatarUrl: avatarUrl,
        deliveryStatus: deliveryStatus,
        text: '[语音通话] ${message.content}',
      );
    case ConversationMessageType.callVideo:
      return TextMessage(
        direction: direction,
        avatarUrl: avatarUrl,
        deliveryStatus: deliveryStatus,
        text: '[视频通话] ${message.content}',
      );
    case ConversationMessageType.text:
      return TextMessage(
        direction: direction,
        avatarUrl: avatarUrl,
        deliveryStatus: deliveryStatus,
        text: message.content,
      );
  }
}
