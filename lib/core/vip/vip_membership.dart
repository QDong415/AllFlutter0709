import 'package:all_flutter0709/core/account/account.dart';

/// 会员是否仍在有效期内。
///
/// Buddy `shouldBeLimit`：`vip == 0` 或 `vip_time < 当前秒` 都算受限。
/// `vip_time == 0` 同样受限，不能当成永久会员。
bool isVipActive(AccountModel account) {
  if (account.vip <= 0) {
    return false;
  }
  final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return account.vipTime >= nowSeconds;
}

/// 男用户等非女账号：非会员或已过期时聊天等功能受限。
bool shouldMaleStyleChatBeLimit(AccountModel account) {
  return account.gender != 2 && !isVipActive(account);
}

/// 女账号：非会员或已过期时受限（例如女对女私聊）。
bool shouldFemaleChatBeLimit(AccountModel account) {
  return account.gender == 2 && !isVipActive(account);
}
