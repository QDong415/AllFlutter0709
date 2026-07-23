import 'package:all_flutter0709/app/app.dart';
import 'package:all_flutter0709/core/account/account_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('allows unauthenticated user to enter main tabs', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const SocialApp(),
      ),
    );
    // 动态页会发起网络请求，避免 pumpAndSettle 一直等待。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('动态 Topic'), findsOneWidget);
    expect(find.text('Login'), findsNothing);
  });
}
