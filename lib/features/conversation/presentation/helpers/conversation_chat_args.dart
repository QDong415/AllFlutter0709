/// 打开单聊页时的预填对方信息（昵称 / 头像 / 身份类型）。
class ConversationChatArgs {
  const ConversationChatArgs({
    this.peerName,
    this.peerAvatar,
    this.peerUserType,
  });

  final String? peerName;
  final String? peerAvatar;

  /// 对方账号类型：0 真人 / 1 AI。
  final int? peerUserType;
}
