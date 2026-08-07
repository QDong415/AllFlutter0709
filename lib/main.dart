import 'package:all_flutter0709/app/app.dart';
import 'package:all_flutter0709/app/theme/app_system_ui.dart';
import 'package:all_flutter0709/core/account/account_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  final preferences = await SharedPreferences.getInstance();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  AppSystemUi.apply(AppSystemUi.overlayStyle);
  runApp(
    LiquidGlassWidgets.wrap(
      adaptiveQuality: true,
      brightnessResolver: Theme.maybeBrightnessOf,
      child: ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const SocialApp(),
      ),
    ),
  );
}
