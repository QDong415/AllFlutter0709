/// 好友选择等场景用的精简用户资料。
class UserBaseModel {
  const UserBaseModel({
    required this.userId,
    required this.name,
    this.avatar,
    this.vip = 0,
  });

  final String userId;
  final String name;
  final String? avatar;
  final int vip;

  factory UserBaseModel.fromJson(Map<String, dynamic> json) {
    return UserBaseModel(
      userId: json['userid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      vip: _readInt(json['vip']),
    );
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
