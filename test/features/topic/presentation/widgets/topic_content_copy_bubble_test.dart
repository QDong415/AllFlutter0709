import 'package:all_flutter0709/features/topic/presentation/widgets/topic_content_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? copiedText;

  setUp(() {
    copiedText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            final arguments = call.arguments;
            if (arguments is Map) {
              copiedText = arguments['text'] as String?;
            }
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('长按动态正文弹出复制气泡，并复制 content', (tester) async {
    const content = '今天的动态内容';
    var cardTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.only(top: 180, left: 24, right: 24),
            child: Material(
              child: InkWell(
                onTap: () => cardTapped = true,
                child: const TopicContentText(
                  text: content,
                  copyOnLongPress: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text(content));
    await tester.pump();
    expect(cardTapped, isTrue);
    expect(find.text('复制'), findsNothing);

    await tester.longPress(find.text(content));
    await tester.pumpAndSettle();

    expect(find.text('复制'), findsOneWidget);

    await tester.tap(find.text('复制'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(copiedText, content);
    expect(find.text('复制成功'), findsOneWidget);
    expect(find.text('复制'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('复制成功'), findsNothing);
  });

  testWidgets('长按带链接的正文仍复制整段 content，不打开链接', (tester) async {
    const content = '看这里 https://example.com 就好';
    String? openedUrl;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.only(top: 180, left: 16),
            child: TopicContentText(
              text: content,
              copyOnLongPress: true,
              onLinkTap: (url) => openedUrl = url,
            ),
          ),
        ),
      ),
    );

    final textRect = tester.getRect(find.text(content));
    await tester.longPressAt(textRect.center);
    await tester.pumpAndSettle();

    expect(openedUrl, isNull);
    expect(find.text('复制'), findsOneWidget);
  });
}
