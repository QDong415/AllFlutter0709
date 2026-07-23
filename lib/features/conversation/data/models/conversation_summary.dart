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
  });

  final String conversationId;
  final String otherUserId;
  final String name;
  final String avatar;
  final String latestMessage;
  final int latestTimeSeconds;
  final int unreadCount;
  final int type;

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
    );
  }
}
