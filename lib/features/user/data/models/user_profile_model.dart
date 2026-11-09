import 'package:all_flutter0709/core/account/user_type.dart';

/// 用户主页资料。
class UserProfileModel {
  const UserProfileModel({
    required this.userId,
    required this.name,
    required this.avatar,
    required this.intro,
    required this.gender,
    required this.age,
    required this.cover,
    required this.cityName,
    required this.followCount,
    required this.fansCount,
    required this.topicCount,
    required this.videoCount,
    required this.follow,
    this.userType = UserType.human,
    this.remark = '',
    this.isBanned = false,
    this.banExpireTime = 0,
    this.coin = 0,
    this.charm = 0,
    this.vip = 0,
    this.vipTime = 0,
  });

  final String userId;
  final String name;
  final String avatar;
  final String intro;
  final int gender;
  final int age;
  final String cover;
  final String cityName;
  final int followCount;
  final int fansCount;
  final int topicCount;
  final int videoCount;

  /// 关注关系：0 未关注 / 1 已关注 / 2 TA关注我 / 3 互关。
  final int follow;

  /// 账号类型：0 真人 / 1 AI。
  final int userType;

  /// 我给对方设置的备注。个人主页标题不用它，只给设置弹框和聊天显示名。
  final String remark;

  /// 当前是否处于系统禁言状态。
  final bool isBanned;

  /// 系统禁言的具体解除时间戳；0 表示永久。
  final int banExpireTime;

  /// 金币。只有看自己的资料时用于更新本地余额。
  final int coin;

  /// 魅力值。收礼累计。
  final int charm;

  /// 会员：0 普通 / 1 VIP / 2 SVIP。
  final int vip;

  /// 会员到期时间戳（秒）。客户端门禁与 Buddy `vip_time` 一致。
  final int vipTime;

  /// 系统禁言展示文案。
  String get banLabel {
    if (!isBanned) return '';
    if (banExpireTime <= 0) return '永久禁言';
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      banExpireTime * 1000,
      isUtc: true,
    ).add(const Duration(hours: 8));
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '禁言至 ${dateTime.year}-$month-$day';
  }

  /// 性别文案；0 或未知返回 null。
  String? get genderLabel {
    switch (gender) {
      case 1:
        return '男';
      case 2:
        return '女';
      default:
        return null;
    }
  }

  /// 是否展示性别标签。
  bool get hasGender => gender == 1 || gender == 2;

  /// 是否展示年龄标签。
  bool get hasAge => age > 0;

  /// 是否展示城市标签。
  bool get hasCity => cityName.trim().isNotEmpty;

  /// 是否为 AI 账号。
  bool get isAi => UserType.isAi(userType);

  /// 服务端对隐藏关注/粉丝返回 -1，主页展示为 *。
  static const int hiddenSocialCount = -1;

  String get followCountText =>
      followCount < 0 ? '*' : '$followCount';

  String get fansCountText => fansCount < 0 ? '*' : '$fansCount';

  /// 是否有任意资料标签。
  bool get hasAnyTag => isAi || hasGender || hasAge || hasCity;

  UserProfileModel copyWith({
    String? userId,
    String? name,
    String? avatar,
    String? intro,
    int? gender,
    int? age,
    String? cover,
    String? cityName,
    int? followCount,
    int? fansCount,
    int? topicCount,
    int? videoCount,
    int? follow,
    int? userType,
    String? remark,
    bool? isBanned,
    int? banExpireTime,
    int? coin,
    int? charm,
    int? vip,
    int? vipTime,
  }) {
    return UserProfileModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      intro: intro ?? this.intro,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      cover: cover ?? this.cover,
      cityName: cityName ?? this.cityName,
      followCount: followCount ?? this.followCount,
      fansCount: fansCount ?? this.fansCount,
      topicCount: topicCount ?? this.topicCount,
      videoCount: videoCount ?? this.videoCount,
      follow: follow ?? this.follow,
      userType: userType ?? this.userType,
      remark: remark ?? this.remark,
      isBanned: isBanned ?? this.isBanned,
      banExpireTime: banExpireTime ?? this.banExpireTime,
      coin: coin ?? this.coin,
      charm: charm ?? this.charm,
      vip: vip ?? this.vip,
      vipTime: vipTime ?? this.vipTime,
    );
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: _readString(json['userid']),
      name: _readString(json['name']),
      avatar: _readString(json['avatar']),
      intro: _readString(json['intro']),
      gender: _readInt(json['gender']),
      age: _readInt(json['age']),
      cover: _readString(json['cover']),
      cityName: _readString(json['cityname']),
      followCount: _readInt(json['followcount']),
      fansCount: _readInt(json['fanscount']),
      topicCount: _readInt(json['topiccount']),
      videoCount: _readInt(json['videocount']),
      follow: _readInt(json['follow']),
      userType: UserType.parse(json['user_type']),
      remark: _readString(json['remark']),
      isBanned: _readInt(json['is_banned']) == 1,
      banExpireTime: _readInt(json['expire_time']),
      coin: _readInt(json['coin']),
      charm: _readInt(json['charm']),
      vip: _readInt(json['vip']),
      vipTime: _readInt(json['vip_time']),
    );
  }

  static String _readString(Object? value) => value?.toString() ?? '';

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
