/// AI 聊天「对方正在输入」状态。
///
/// 只在当前打开的聊天页有效：发出消息后开始等待，收到新的对方消息后结束。
/// 离开页面不持久化，重新进入不根据历史消息回查。
class ChatAiTypingHelper {
  bool _waiting = false;
  int _incomingCountAtStart = 0;

  /// 用户刚发出消息后开始等待 AI 回复。
  void startWaiting(int incomingCount) {
    _waiting = true;
    _incomingCountAtStart = incomingCount;
  }

  /// 当前是否应显示「正在输入」。对方消息变多后自然结束。
  bool isTyping(int incomingCount) {
    if (!_waiting) {
      return false;
    }
    return incomingCount <= _incomingCountAtStart;
  }
}
