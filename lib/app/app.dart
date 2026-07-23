import 'dart:async';

import 'package:all_flutter0709/app/router/app_router.dart';
import 'package:all_flutter0709/core/push/getui_push_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SocialApp extends ConsumerStatefulWidget {
  const SocialApp({super.key});

  static const appSurfaceColor = Color(0xFFF7F2FA);

  @override
  ConsumerState<SocialApp> createState() => _SocialAppState();
}

class _SocialAppState extends ConsumerState<SocialApp> {
  @override
  void initState() {
    super.initState();
    //由于ref.read(getuiPushServiceProvider).initialize() 只能在 app 启动时候走一次就行了
    // 但是因为StatelessWidget没有 init 方法，只有 build 方法，但是 build 会经常触发，所以才改成 StatefulWidget借用initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(getuiPushServiceProvider).initialize());
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Social App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: SocialApp.appSurfaceColor,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: SocialApp.appSurfaceColor,
          indicatorColor: Color(0xFFE9DDF7),
        ),
      ),
      routerConfig: router,
    );
  }
}
