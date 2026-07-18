import 'package:all_flutter0709/app/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SocialApp extends ConsumerWidget {
  const SocialApp({super.key});

  static const appSurfaceColor = Color(0xFFF7F2FA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Social App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: appSurfaceColor,
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
          backgroundColor: appSurfaceColor,
          indicatorColor: Color(0xFFE9DDF7),
        ),
      ),
      routerConfig: router,
    );
  }
}
