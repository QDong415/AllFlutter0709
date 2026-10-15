import 'package:all_flutter0709/core/account/user_type.dart';
import 'package:all_flutter0709/core/utils/value_util.dart';

/// AI 角色发现页的公开展示数据。
class AiCharacterModel {
  const AiCharacterModel({
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.gender,
    required this.age,
    required this.style,
    required this.fullBodyImageUrl,
    required this.greeting,
    required this.tagList,
  });

  final String userId;
  final String name;
  final String? avatarUrl;
  final int gender;
  final int age;
  final String style;
  final String? fullBodyImageUrl;
  final String greeting;
  final List<String> tagList;

  /// AI 账号类型，供用户主页和聊天页预填。
  int get userType => UserType.ai;

  factory AiCharacterModel.fromJson(Map<String, dynamic> json) {
    return AiCharacterModel(
      userId: json['userid']?.toString() ?? '',
      name: _stringOf(json['name'], fallback: 'AI 伙伴'),
      avatarUrl: ValueUtil.getQiniuUrlByFileName(
        _nullableStringOf(json['avatar']),
        thumbnail: true,
      ),
      gender: _intOf(json['gender']),
      age: _intOf(json['age']),
      style: _stringOf(json['style']),
      fullBodyImageUrl: ValueUtil.getQiniuUrlByFileName(
        _nullableStringOf(json['full_body_image']),
        keepOriginal: true,
      ),
      greeting: _stringOf(json['greeting']),
      tagList: _stringListOf(json['tags']),
    );
  }

  static int _intOf(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _stringOf(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _nullableStringOf(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static List<String> _stringListOf(Object? value) {
    if (value is! List) return const <String>[];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
