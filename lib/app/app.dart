import 'dart:async';

import 'package:all_flutter0709/app/router/app_router.dart';
import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/app/theme/app_dimens.dart';
import 'package:all_flutter0709/app/theme/app_system_ui.dart';
import 'package:all_flutter0709/core/bridge/native_events.dart';
import 'package:all_flutter0709/core/push/getui_push_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 应用根 Widget：挂路由、主题，并完成推送 / Bridge 等启动初始化。
class SocialApp extends ConsumerStatefulWidget {
  const SocialApp({super.key});

  /// 兼容旧引用；请优先使用 [AppColors.bodyBackground]。
  static const appSurfaceColor = AppColors.bodyBackground;

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
      // 尽早挂上 Native→Flutter 的 MethodCallHandler / EventChannel 订阅
      NativeEvents.instance.start();
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.bodyBackground,
        ),
        scaffoldBackgroundColor: AppColors.bodyBackground,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.toolbar,
          foregroundColor: AppColors.titleText,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          toolbarHeight: AppDimens.toolbarHeight,
          titleTextStyle: TextStyle(
            color: AppColors.titleText,
            fontSize: AppDimens.toolbarTitleSize,
            fontWeight: FontWeight.w400,
          ),
          iconTheme: IconThemeData(color: AppColors.titleText),
          actionsIconTheme: IconThemeData(color: AppColors.titleText),
          systemOverlayStyle: AppSystemUi.overlayStyle,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.tabBarBackground,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.tabUnselected,
          selectedIconTheme: IconThemeData(
            color: AppColors.primary,
            size: 24,
          ),
          unselectedIconTheme: IconThemeData(
            color: AppColors.tabUnselected,
            size: 24,
          ),
          selectedLabelStyle: TextStyle(fontSize: 12),
          unselectedLabelStyle: TextStyle(fontSize: 12),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: AppDimens.dividerThickness,
          space: AppDimens.dividerThickness,
        ),
      ),
      routerConfig: router,
    );
  }
}
