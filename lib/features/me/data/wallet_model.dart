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

/// 会员说明页的价格和当前会员标记。价格单位是元。
class VipOfferModel {
  const VipOfferModel({
    required this.monthPrice,
    required this.seasonPrice,
    required this.yearPrice,
    required this.vip,
    required this.vipTime,
  });

  final int monthPrice;
  final int seasonPrice;
  final int yearPrice;
  final int vip;

  /// 到期时间戳，秒。没有 vip_time 列时为 0。
  final int vipTime;

  factory VipOfferModel.fromJson(Map<String, dynamic> json) {
    return VipOfferModel(
      monthPrice: _readInt(json['monthprice'], fallback: 30),
      seasonPrice: _readInt(json['seasonprice'], fallback: 80),
      yearPrice: _readInt(json['yearprice'], fallback: 240),
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
