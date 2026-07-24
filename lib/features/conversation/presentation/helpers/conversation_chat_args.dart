/// 打开单聊页时的预填对方信息（昵称 / 头像）。
class ConversationChatArgs {
  const ConversationChatArgs({this.peerName, this.peerAvatar});

  final String? peerName;
  final String? peerAvatar;
}
