class AccountModel {
  const AccountModel({
    required this.userId,
    required this.mobile,
    required this.name,
    required this.avatar,
    required this.intro,
    required this.gender,
    required this.age,
    required this.cover,
    required this.tags,
    required this.cityId,
    required this.cityName,
    required this.cid,
    required this.hwid,
    required this.followCount,
    required this.fansCount,
    required this.topicCount,
    required this.videoCount,
    required this.follow,
  });

  final String userId;
  final String mobile;
  final String name;
  final String avatar;
  final String intro;
  final int gender;
  final int age;
  final String cover;
  final String tags;
  final String cityId;
  final String cityName;
  final String cid;
  final String hwid;
  final int followCount;
  final int fansCount;
  final int topicCount;
  final int videoCount;
  final int follow;

  bool get isValid => userId.trim().isNotEmpty;

  AccountModel copyWith({
    String? userId,
    String? mobile,
    String? name,
    String? avatar,
    String? intro,
    int? gender,
    int? age,
    String? cover,
    String? tags,
    String? cityId,
    String? cityName,
    String? cid,
    String? hwid,
    int? followCount,
    int? fansCount,
    int? topicCount,
    int? videoCount,
    int? follow,
  }) {
    return AccountModel(
      userId: userId ?? this.userId,
      mobile: mobile ?? this.mobile,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      intro: intro ?? this.intro,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      cover: cover ?? this.cover,
      tags: tags ?? this.tags,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      cid: cid ?? this.cid,
      hwid: hwid ?? this.hwid,
      followCount: followCount ?? this.followCount,
      fansCount: fansCount ?? this.fansCount,
      topicCount: topicCount ?? this.topicCount,
      videoCount: videoCount ?? this.videoCount,
      follow: follow ?? this.follow,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userid': userId,
      'mobile': mobile,
      'name': name,
      'avatar': avatar,
      'intro': intro,
      'gender': gender,
      'age': age,
      'cover': cover,
      'tags': tags,
      'cityid': cityId,
      'cityname': cityName,
      'cid': cid,
      'hwid': hwid,
      'followcount': followCount,
      'fanscount': fansCount,
      'topiccount': topicCount,
      'videocount': videoCount,
      'follow': follow,
    };
  }

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      userId: _readString(json['userid']),
      mobile: _readString(json['mobile']),
      name: _readString(json['name']),
      avatar: _readString(json['avatar']),
      intro: _readString(json['intro']),
      gender: _readInt(json['gender']),
      age: _readInt(json['age']),
      cover: _readString(json['cover']),
      tags: _readString(json['tags']),
      cityId: _readString(json['cityid']),
      cityName: _readString(json['cityname']),
      cid: _readString(json['cid']),
      hwid: _readString(json['hwid']),
      followCount: _readInt(json['followcount']),
      fansCount: _readInt(json['fanscount']),
      topicCount: _readInt(json['topiccount']),
      videoCount: _readInt(json['videocount']),
      follow: _readInt(json['follow']),
    );
  }

  static String _readString(Object? value) => value?.toString() ?? '';

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
