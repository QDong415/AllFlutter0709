import 'dart:math' as math;

/// 服务端以「分」存储、客户端以「元」展示时的换算。
abstract final class MoneyUtil {
  MoneyUtil._();

  /// 分 → 元（四舍五入到整数，用于会员价等整元标价）。
  static int centsToYuanInt(int cents) {
    if (cents <= 0) {
      return 0;
    }
    return (cents / 100).round();
  }

  /// 分 → 元（保留两位小数，四舍五入）。
  static double centsToYuanDouble(int cents) {
    if (cents <= 0) {
      return 0;
    }
    final scaled = cents / 100.0;
    return math.max(0, (scaled * 100).roundToDouble()) / 100.0;
  }

  /// 魅力提现 `reqmoney`（分，元×100）。Buddy 传的是 `charm*cashscale*100`，库表按分存应用本公式。
  static int charmWithdrawReqmoneyCents(int reqcharm, int cashScale) {
    if (reqcharm <= 0) {
      return 0;
    }
    final scale = cashScale > 0 ? cashScale : 20;
    return ((reqcharm * 100) / scale).round();
  }
}
