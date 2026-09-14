import 'package:all_flutter0709/core/account/user_type.dart';

/// 会话列表摘要。
class ConversationSummary {
  const ConversationSummary({
    required this.conversationId,
    required this.otherUserId,
    required this.name,
    required this.avatar,
    required this.latestMessage,
    required this.latestTimeSeconds,
    required this.unreadCount,
    required this.type,
    this.userType = UserType.human,
  });

  final String conversationId;
  final String otherUserId;
  final String name;
  final String avatar;
  final String latestMessage;
  final int latestTimeSeconds;
  final int unreadCount;
  final int type;

  /// 对方账号类型：0 真人 / 1 AI。
  final int userType;

  /// 是否为 AI 会话对方。
  bool get isAi => UserType.isAi(userType);

  DateTime get latestTime =>
      DateTime.fromMillisecondsSinceEpoch(latestTimeSeconds * 1000);

  ConversationSummary copyWith({
    String? conversationId,
    String? otherUserId,
    String? name,
    String? avatar,
    String? latestMessage,
    int? latestTimeSeconds,
    int? unreadCount,
    int? type,
    int? userType,
  }) {
    return ConversationSummary(
      conversationId: conversationId ?? this.conversationId,
      otherUserId: otherUserId ?? this.otherUserId,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      latestMessage: latestMessage ?? this.latestMessage,
      latestTimeSeconds: latestTimeSeconds ?? this.latestTimeSeconds,
      unreadCount: unreadCount ?? this.unreadCount,
      type: type ?? this.type,
      userType: userType ?? this.userType,
    );
  }
}
