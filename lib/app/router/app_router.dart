import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/features/auth/presentation/login_page.dart';
import 'package:all_flutter0709/features/auth/presentation/signup_page.dart';
import 'package:all_flutter0709/features/conversation/presentation/conversation_chat_page.dart';
import 'package:all_flutter0709/features/conversation/presentation/conversation_page.dart';
import 'package:all_flutter0709/features/home/presentation/main_tab_scaffold.dart';
import 'package:all_flutter0709/features/me/presentation/me_page.dart';
import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:all_flutter0709/features/topic/presentation/topic_detail_page.dart';
import 'package:all_flutter0709/features/topic/presentation/topic_page.dart';
import 'package:all_flutter0709/features/user/presentation/helpers/user_detail_navigation.dart';
import 'package:all_flutter0709/features/user/presentation/user_detail_page.dart';
import 'package:all_flutter0709/features/video/data/models/video_model.dart';
import 'package:all_flutter0709/features/video/presentation/missing_video_page.dart';
import 'package:all_flutter0709/features/video/presentation/video_detail_page.dart';
import 'package:all_flutter0709/features/video/presentation/video_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ValueNotifier<Object?>(null);
  ref.onDispose(refreshListenable.dispose);
  ref.listen(accountProvider, (previous, next) {
    refreshListenable.value = Object();
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.topic,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final loggedIn = ref.read(accountProvider) != null;
      final isAuthPage =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup;

      // 未登录可浏览主流程；需登录操作由 AccountGuardX 按需跳转登录页。
      // 已登录访问登录/注册页时仍回到动态页。
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
        parentNavigatorKey: _rootNavigatorKey,
        path: '${AppRoutes.user}/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          final args = state.extra is UserDetailArgs
              ? state.extra! as UserDetailArgs
              : null;
          return UserDetailPage(
            userId: userId,
            initialName: args?.name,
            initialAvatar: args?.avatar,
          );
        },
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
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: TopicPage()),
                routes: [
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: AppRoutes.topicDetail,
                    builder: (context, state) {
                      final tid = state.pathParameters['tid'] ?? '';
                      final topicModel = state.extra is TopicModel
                          ? state.extra! as TopicModel
                          : null;
                      return TopicDetailPage(tid: tid, topicModel: topicModel);
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
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: VideoPage()),
                routes: [
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: AppRoutes.videoDetail,
                    builder: (context, state) {
                      final video = state.extra;
                      if (video is! VideoModel) {
                        return const MissingVideoPage();
                      }
                      return VideoDetailPage(video: video);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.conversation,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ConversationPage()),
                routes: [
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: AppRoutes.conversationChat,
                    builder: (context, state) {
                      final chatId = state.pathParameters['chatId'] ?? '';
                      return ConversationChatPage(chatId: chatId);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.me,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: MePage()),
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
});

final _rootNavigatorKey = GlobalKey<NavigatorState>();
