import 'package:all_flutter0709/core/utils/money_util.dart';

/// 充值说明页需要的金币和小秘书。
class ChargeGuideModel {
  const ChargeGuideModel({
    required this.coin,
    required this.secretaryUserId,
    required this.secretaryName,
    required this.secretaryAvatar,
  });

  final int coin;
  final String secretaryUserId;
  final String secretaryName;
  final String secretaryAvatar;

  factory ChargeGuideModel.fromJson(Map<String, dynamic> json) {
    return ChargeGuideModel(
      coin: _readInt(json['coin']),
      secretaryUserId: '${json['secretary_userid'] ?? ''}',
      secretaryName: '${json['secretary_name'] ?? ''}',
      secretaryAvatar: '${json['secretary_avatar'] ?? ''}',
    );
  }
}

/// 会员说明页的价格和当前会员标记。
///
/// 服务端 `monthprice` / `seasonprice` / `yearprice` 单位为分；展示用 [monthPriceYuan] 等。
class VipOfferModel {
  const VipOfferModel({
    required this.monthPriceCents,
    required this.seasonPriceCents,
    required this.yearPriceCents,
    required this.vip,
    required this.vipTime,
  });

  static const defaultMonthPriceCents = 3000;
  static const defaultSeasonPriceCents = 8000;
  static const defaultYearPriceCents = 24000;

  final int monthPriceCents;
  final int seasonPriceCents;
  final int yearPriceCents;
  final int vip;

  /// 到期时间戳，秒。没有 vip_time 列时为 0。
  final int vipTime;

  int get monthPriceYuan => MoneyUtil.centsToYuanInt(monthPriceCents);
  int get seasonPriceYuan => MoneyUtil.centsToYuanInt(seasonPriceCents);
  int get yearPriceYuan => MoneyUtil.centsToYuanInt(yearPriceCents);

  factory VipOfferModel.fromJson(Map<String, dynamic> json) {
    return VipOfferModel(
      monthPriceCents: _readInt(
        json['monthprice'],
        fallback: defaultMonthPriceCents,
      ),
      seasonPriceCents: _readInt(
        json['seasonprice'],
        fallback: defaultSeasonPriceCents,
      ),
      yearPriceCents: _readInt(
        json['yearprice'],
        fallback: defaultYearPriceCents,
      ),
      vip: _readInt(json['vip']),
      vipTime: _readInt(json['vip_time']),
    );
  }
}

/// 魅力提现页的余额、比例和上次填写的支付宝信息。
class CharmCashModel {
  const CharmCashModel({
    required this.charm,
    required this.cashScale,
    required this.account,
    required this.realName,
  });

  final int charm;

  /// 多少魅力兑换 1 元。
  final int cashScale;
  final String account;
  final String realName;

  factory CharmCashModel.fromJson(Map<String, dynamic> json) {
    final scale = _readInt(json['cashscale'], fallback: 20);
    return CharmCashModel(
      charm: _readInt(json['charm']),
      cashScale: scale > 0 ? scale : 20,
      account: '${json['account'] ?? ''}',
      realName: '${json['realname'] ?? ''}',
    );
  }
}

int _readInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse('$value') ?? fallback;
}
