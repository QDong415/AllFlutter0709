import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/core/account/account.dart';
import 'package:all_flutter0709/features/auth/presentation/login_page.dart';
import 'package:all_flutter0709/features/auth/presentation/signup_page.dart';
import 'package:all_flutter0709/features/home/presentation/main_tab_scaffold.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.topic,
    refreshListenable: Account.instance,
    redirect: (context, state) {
      final loggedIn = Account.instance.isLoggedIn;
      final isAuthPage = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup;

      if (!loggedIn && !isAuthPage) {
        return AppRoutes.login;
      }

      if (loggedIn && isAuthPage) {
        return AppRoutes.topic;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: AppRoutes.topic,
        builder: (context, state) => MainTabScaffold(
          location: state.uri.toString(),
        ),
      ),
      GoRoute(
        path: AppRoutes.video,
        builder: (context, state) => MainTabScaffold(
          location: state.uri.toString(),
        ),
      ),
      GoRoute(
        path: AppRoutes.conversation,
        builder: (context, state) => MainTabScaffold(
          location: state.uri.toString(),
        ),
      ),
      GoRoute(
        path: AppRoutes.me,
        builder: (context, state) => MainTabScaffold(
          location: state.uri.toString(),
        ),
      ),
    ],
  );
}
