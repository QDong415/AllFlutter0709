/// 非会员限制导致不调 `chat/send`（本地消息仍保留，对齐 Buddy `needSuccess=false`）。
class VipChatLimitException implements Exception {
  VipChatLimitException(this.message);

  final String message;

  @override
  String toString() => message;
}
