/// 用户主页资料，对齐 iTopicX `UserBean` / `user/profile`。
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

  /// 是否有任意资料标签。
  bool get hasAnyTag => hasGender || hasAge || hasCity;

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
    );
  }

  static String _readString(Object? value) => value?.toString() ?? '';

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
