/// 隐私扩展：`user_extend` 三个开关，0 不隐藏，1 隐藏。
class UserExtendModel {
  const UserExtendModel({
    this.hideGift = false,
    this.hideFans = false,
    this.hideFollow = false,
  });

  final bool hideGift;
  final bool hideFans;
  final bool hideFollow;

  UserExtendModel copyWith({
    bool? hideGift,
    bool? hideFans,
    bool? hideFollow,
  }) {
    return UserExtendModel(
      hideGift: hideGift ?? this.hideGift,
      hideFans: hideFans ?? this.hideFans,
      hideFollow: hideFollow ?? this.hideFollow,
    );
  }

  factory UserExtendModel.fromJson(Map<String, dynamic> json) {
    return UserExtendModel(
      hideGift: _readFlag(json['hidegift']),
      hideFans: _readFlag(json['hidefans']),
      hideFollow: _readFlag(json['hidefollow']),
    );
  }

  static bool _readFlag(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value.toInt() == 1;
    }
    return int.tryParse(value?.toString() ?? '') == 1;
  }
}
