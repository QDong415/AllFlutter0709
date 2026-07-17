import 'package:all_flutter0709/app/router/app_router.dart';
import 'package:flutter/material.dart';

class SocialApp extends StatelessWidget {
  const SocialApp({super.key});

  static const appSurfaceColor = Color(0xFFF7F2FA);

  @override
  Widget build(BuildContext context) {
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
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: appSurfaceColor,
          indicatorColor: Color(0xFFE9DDF7),
        ),
      ),
      routerConfig: AppRouter.router,
    );
  }
}
