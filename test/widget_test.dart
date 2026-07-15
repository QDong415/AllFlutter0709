import 'package:all_flutter0709/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('redirects unauthenticated user to login page', (WidgetTester tester) async {
    await tester.pumpWidget(const SocialApp());
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('社交 App 登录入口'), findsOneWidget);
  });
}
