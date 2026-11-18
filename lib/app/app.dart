import 'dart:async';

import 'package:all_flutter0709/app/router/app_router.dart';
import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/app/theme/app_palette.dart';
import 'package:all_flutter0709/app/theme/app_theme.dart';
import 'package:all_flutter0709/app/theme/app_system_ui.dart';
import 'package:all_flutter0709/app/theme/app_theme_preference.dart';
import 'package:all_flutter0709/app/theme/app_typography.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
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

class _SocialAppState extends ConsumerState<SocialApp>
    with WidgetsBindingObserver {
  Brightness? _appliedSystemUiBrightness;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    //由于ref.read(getuiPushServiceProvider).initialize() 只能在 app 启动时候走一次就行了
    // 但是因为StatelessWidget没有 init 方法，只有 build 方法，但是 build 会经常触发，所以才改成 StatefulWidget借用initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 尽早挂上 Native→Flutter 的 MethodCallHandler / EventChannel 订阅
      NativeEvents.instance.start();
      unawaited(ref.read(getuiPushServiceProvider).initialize());
      if (ref.read(accountProvider) != null) {
        unawaited(ref.read(accountProvider.notifier).refreshMyProfile());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final preference = ref.watch(appThemePreferenceProvider);
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final palette = AppPalette.forBrightness(
      preference.resolve(platformBrightness),
    );
    AppSystemUi.themeBrightness = palette.brightness;
    if (_appliedSystemUiBrightness != palette.brightness) {
      _appliedSystemUiBrightness = palette.brightness;
      AppSystemUi.apply(AppSystemUi.overlayForToolbar(palette.brightness));
    }
    return MaterialApp.router(
      title: '梦缘AI',
      debugShowCheckedModeBanner: false,
      builder: AppTypography.wrapWithIosTextScale,
      theme: AppTheme.build(palette),
      routerConfig: router,
    );
  }
}
