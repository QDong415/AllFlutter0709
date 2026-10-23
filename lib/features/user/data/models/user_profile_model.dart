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
    );
  }

  static String _readString(Object? value) => value?.toString() ?? '';

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
