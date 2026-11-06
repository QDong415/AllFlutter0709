import 'package:all_flutter0709/core/account/account.dart';
import 'package:all_flutter0709/core/account/user_type.dart';
import 'package:all_flutter0709/core/config/app_config.dart';
import 'package:all_flutter0709/core/vip/vip_membership.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';

/// 本地消息已入库后，是否允许请求 `/api/chat/send`。
///
/// 文本和语音的条数用 SharedPreferences 里「今天已成功发出」的次数，
/// 删除本地聊天记录不会恢复额度。图片和礼物不占这条额度，仍会发给服务器。
class VipChatSendEvaluation {
  const VipChatSendEvaluation._({
    required this.allowServerSend,
    this.tipMessage,
    this.promptOpenVip = false,
  });

  const VipChatSendEvaluation.allow({String? tipMessage})
    : this._(allowServerSend: true, tipMessage: tipMessage);

  const VipChatSendEvaluation.blocked({String? tipMessage})
    : this._(allowServerSend: false, tipMessage: tipMessage);

  const VipChatSendEvaluation.blockPickImage()
    : this._(allowServerSend: false, promptOpenVip: true);

  final bool allowServerSend;
  final String? tipMessage;
  final bool promptOpenVip;
}

class VipChatSendPolicy {
  const VipChatSendPolicy._();

  static const femaleBlockedTip = '非会员限制，不可以给女性发信息';

  static VipChatSendEvaluation evaluateAfterLocalInsert({
    required AccountModel account,
    required ConversationMessage message,
    required int peerGender,
    required int sentCount,
    required AppConfig config,
  }) {
    if (UserType.isAi(message.otherUserType)) {
      return const VipChatSendEvaluation.allow();
    }

    final isGift = message.messageType == ConversationMessageType.gift;
    final isImage = message.messageType == ConversationMessageType.image;
    final honorServerBlock = !isGift && !isImage;
    final tips = <String>[];
    var blockServer = false;

    if (config.allowChatFemaleToFemale == 0 &&
        shouldFemaleChatBeLimit(account) &&
        peerGender == 2) {
      tips.add(femaleBlockedTip);
      if (honorServerBlock) {
        blockServer = true;
      }
    }

    final countsTowardDaily =
        message.messageType == ConversationMessageType.text ||
        message.messageType == ConversationMessageType.voice;
    if (countsTowardDaily && shouldMaleStyleChatBeLimit(account)) {
      if (sentCount >= config.allowChatCount) {
        blockServer = true;
        tips.add('非会员限制，今天还可发送0条信息');
      } else {
        final dailyTip = _buddyDailyLimitTip(
          historyCount: sentCount + 1,
          dailyLimit: config.allowChatCount,
        );
        if (dailyTip != null) {
          tips.add(dailyTip);
        }
      }
    }

    final tip = tips.isEmpty ? null : tips.join('\n');
    if (blockServer) {
      return VipChatSendEvaluation.blocked(tipMessage: tip);
    }
    return VipChatSendEvaluation.allow(tipMessage: tip);
  }

  /// 选图前：非会员且 `allow_chat_image==0`（Buddy 相册按钮只弹 VIP，不发图）。
  static VipChatSendEvaluation beforePickImage({
    required AccountModel account,
    required AppConfig config,
  }) {
    if (shouldMaleStyleChatBeLimit(account) && config.allowChatImage == 0) {
      return const VipChatSendEvaluation.blockPickImage();
    }
    return const VipChatSendEvaluation.allow();
  }

  /// 对齐 Buddy 在 `getChatTotalTodayCount` 之后插入的条数提示。
  static String? _buddyDailyLimitTip({
    required int historyCount,
    required int dailyLimit,
  }) {
    if (dailyLimit <= 0) {
      return null;
    }
    var lastCount = 0;
    if (historyCount == 1 ||
        historyCount == 9 ||
        historyCount == 19 ||
        historyCount > dailyLimit ||
        historyCount == dailyLimit - 1) {
      lastCount = dailyLimit - historyCount;
    }
    if (lastCount == 0) {
      return null;
    }
    final displayRemaining = historyCount >= dailyLimit ? 0 : lastCount;
    return '非会员限制，今天还可发送$displayRemaining条信息';
  }
}
