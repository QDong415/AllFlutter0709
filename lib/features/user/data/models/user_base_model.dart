import 'package:all_flutter0709/core/account/user_type.dart';

/// 好友选择、匹配列表等场景用的精简用户资料。
class UserBaseModel {
  const UserBaseModel({
    required this.userId,
    required this.name,
    this.avatar,
    this.vip = 0,
    this.gender = 0,
    this.age = 0,
    this.cityName = '',
    this.openTime = 0,
    this.userType = UserType.human,
  });

  final String userId;
  final String name;
  final String? avatar;
  final int vip;
  final int gender;
  final int age;
  final String cityName;
  final int openTime;

  /// 账号类型：0 真人 / 1 AI。
  final int userType;

  /// 是否为 AI 账号。
  bool get isAi => UserType.isAi(userType);

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

  factory UserBaseModel.fromJson(Map<String, dynamic> json) {
    return UserBaseModel(
      userId: json['userid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      vip: _readInt(json['vip']),
      gender: _readInt(json['gender']),
      age: _readInt(json['age']),
      cityName: json['cityname']?.toString() ?? '',
      openTime: _readInt(json['open_time']),
      userType: UserType.parse(json['user_type']),
    );
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
