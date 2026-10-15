import 'package:all_flutter0709/features/ai/data/models/ai_character_model.dart';
import 'package:all_flutter0709/features/ai/presentation/widgets/ai_character_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const characterModel = AiCharacterModel(
    userId: '10001',
    name: '林晚晚',
    avatarUrl: null,
    gender: 2,
    age: 22,
    style: '温柔',
    fullBodyImageUrl: null,
    greeting: '会把你的坏心情慢慢熨平。',
    tagList: <String>[],
  );

  testWidgets('角色卡展示公开信息并响应聊天操作', (tester) async {
    var chatTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 400,
            child: AiCharacterCard(
              characterModel: characterModel,
              onTap: () {},
              onChatTap: () => chatTapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('林晚晚'), findsOneWidget);
    expect(find.text('温柔'), findsOneWidget);
    expect(find.text('会把你的坏心情慢慢熨平。'), findsOneWidget);
    expect(find.text('开始聊天'), findsOneWidget);

    await tester.tap(find.text('开始聊天'));
    expect(chatTapped, isTrue);
  });
}
