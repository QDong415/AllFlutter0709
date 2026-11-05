/// 与 Android 列表空态一致：展示用文案（服务端可能返回旧措辞，识别后统一成这句）。
const giftListHiddenMessage = '对方隐藏了收到礼物列表';

/// 服务端历史文案，仍用于识别 hidegift 错误。
const _giftListHiddenServerMessages = <String>[
  '对方隐藏了收到礼物列表',
  '对方隐藏了礼物列表',
];

bool isGiftListHiddenError(Object error) {
  if (error is GiftListHiddenException) {
    return true;
  }
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  if (text.isEmpty) {
    return false;
  }
  for (final marker in _giftListHiddenServerMessages) {
    if (text.contains(marker)) {
      return true;
    }
  }
  return text.contains('隐藏') && text.contains('礼物');
}

String giftErrorMessage(Object error) {
  if (isGiftListHiddenError(error)) {
    return giftListHiddenMessage;
  }
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  return text.isEmpty ? '加载失败' : text;
}

/// 礼物墙 / 流水接口因 hidegift 被拒绝时抛出，调用方应内联展示 [message]，不要 Toast。
class GiftListHiddenException implements Exception {
  GiftListHiddenException([this.message = giftListHiddenMessage]);

  final String message;

  @override
  String toString() => message;
}
