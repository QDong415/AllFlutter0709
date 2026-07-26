import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';
import 'package:all_flutter0709/features/conversation/presentation/models/chat_item.dart';
import 'package:intl/intl.dart';

/// 将会话消息映射为聊天气泡列表项（含时间 tips）。
List<ChatItem> buildChatItems(
  List<ConversationMessage> messages, {
  String myAvatar = '',
  String peerAvatar = '',
}) {
  final items = <ChatItem>[];
  ConversationMessage? previous;

  for (final message in messages) {
    if (previous == null ||
        message.createTimeSeconds - previous.createTimeSeconds > 5 * 60) {
      items.add(
        TimeItem(label: DateFormat('HH:mm').format(message.createTime)),
      );
    }
    items.add(
      _mapMessage(
        message,
        myAvatar: myAvatar,
        peerAvatar: peerAvatar,
      ),
    );
    previous = message;
  }

  return items;
}

ChatItem _mapMessage(
  ConversationMessage message, {
  required String myAvatar,
  required String peerAvatar,
}) {
  final direction = message.isSender
      ? MessageDirection.right
      : MessageDirection.left;
  // 己方头像用当前账号；对方用 otherPhoto，空则回退会话头像。
  final avatarFileName = message.isSender
      ? myAvatar
      : (message.otherPhoto.isNotEmpty ? message.otherPhoto : peerAvatar);
  final avatarUrl =
      ValueUtil.getQiniuUrlByFileName(avatarFileName, thumbnail: true) ?? '';
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
