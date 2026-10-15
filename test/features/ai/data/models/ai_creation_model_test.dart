import 'package:all_flutter0709/features/ai/data/models/ai_creation_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('解析 AI 创建草稿和候选图片', () {
    final creationModel = AiCreationModel.fromJson(<String, dynamic>{
      'creation_id': '12',
      'status': 'ready',
      'name': '小晴',
      'gender': 2,
      'personality': 'gentle',
      'outfit': 'casual',
      'career': 'designer',
      'avatar_image': 'avatar.jpg',
      'full_body_image': 'full.jpg',
      'error_message': '',
      'ai_userid': 0,
    });

    expect(creationModel.creationId, 12);
    expect(creationModel.isReady, isTrue);
    expect(creationModel.avatarUrl, contains('avatar.jpg'));
    expect(creationModel.fullBodyImageUrl, contains('full.jpg'));
  });
}
