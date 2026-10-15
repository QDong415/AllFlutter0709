import 'package:all_flutter0709/core/account/user_type.dart';
import 'package:all_flutter0709/features/ai/data/models/ai_character_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson 解析 AI 角色公开字段', () {
    final characterModel = AiCharacterModel.fromJson(<String, dynamic>{
      'userid': 10001,
      'name': '林晚晚',
      'avatar': 'avatar.webp',
      'gender': '2',
      'age': 22,
      'style': '温柔',
      'full_body_image': 'full.webp',
      'greeting': '会把你的坏心情慢慢熨平。',
      'tags': <String>['治愈', '陪伴'],
    });

    expect(characterModel.userId, '10001');
    expect(characterModel.name, '林晚晚');
    expect(characterModel.gender, 2);
    expect(characterModel.style, '温柔');
    expect(characterModel.greeting, '会把你的坏心情慢慢熨平。');
    expect(characterModel.tagList, <String>['治愈', '陪伴']);
    expect(characterModel.userType, UserType.ai);
    expect(characterModel.avatarUrl, contains('avatar.webp'));
    expect(characterModel.fullBodyImageUrl, contains('full.webp'));
  });

  test('fromJson 对空数据使用安全默认值', () {
    final characterModel = AiCharacterModel.fromJson(<String, dynamic>{});

    expect(characterModel.name, 'AI 伙伴');
    expect(characterModel.avatarUrl, isNull);
    expect(characterModel.fullBodyImageUrl, isNull);
    expect(characterModel.tagList, isEmpty);
  });
}
