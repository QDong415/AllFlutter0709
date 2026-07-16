import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/core/account/account.dart';
import 'package:all_flutter0709/features/auth/presentation/login_page.dart';
import 'package:all_flutter0709/features/auth/presentation/signup_page.dart';
import 'package:all_flutter0709/features/conversation/presentation/conversation_page.dart';
import 'package:all_flutter0709/features/home/presentation/main_tab_scaffold.dart';
import 'package:all_flutter0709/features/me/presentation/me_page.dart';
import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:all_flutter0709/features/topic/presentation/topic_detail_page.dart';
import 'package:all_flutter0709/features/topic/presentation/topic_page.dart';
import 'package:all_flutter0709/features/video/presentation/video_page.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainTabScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.topic,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: TopicPage(),
                ),
                routes: [
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: AppRoutes.topicDetail,
                    builder: (context, state) {
                      final tid = state.pathParameters['tid'] ?? '';
                      final topic = state.extra is TopicModel
                          ? state.extra! as TopicModel
                          : null;
                      return TopicDetailPage(
                        tid: tid,
                        topic: topic,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.video,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: VideoPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.conversation,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ConversationPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.me,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: MePage(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      return const LoginPage();
    },
  );
}
