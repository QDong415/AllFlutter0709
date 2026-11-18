import 'package:all_flutter0709/core/account/account_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 黑夜模式偏好，存本地，不跟账号走。
///
/// 取值与 iOS `NSUserDefaults` 的 `interface` 一致：
/// 0 跟随系统，1 普通模式，2 黑夜模式。
enum AppThemePreference {
  /// 跟随系统。
  system(0),

  /// 固定浅色。
  light(1),

  /// 固定深色。
  dark(2);

  const AppThemePreference(this.storageValue);

  /// 写入 SharedPreferences 的整数。
  final int storageValue;

  /// 设置页当前值文案，对齐 iOS `findInterFaceString`。
  String get settingsLabel => switch (this) {
    AppThemePreference.system => '跟随系统',
    AppThemePreference.light => '固定普通模式',
    AppThemePreference.dark => '固定黑夜模式',
  };

  /// 从本地整数恢复。无法识别时按跟随系统。
  static AppThemePreference fromStorage(int value) {
    return switch (value) {
      1 => AppThemePreference.light,
      2 => AppThemePreference.dark,
      _ => AppThemePreference.system,
    };
  }

  /// 解析成实际明暗。跟随系统时用 [platform]。
  Brightness resolve(Brightness platform) {
    return switch (this) {
      AppThemePreference.system => platform,
      AppThemePreference.light => Brightness.light,
      AppThemePreference.dark => Brightness.dark,
    };
  }
}

/// 黑夜模式偏好。
final appThemePreferenceProvider =
    NotifierProvider<AppThemePreferenceNotifier, AppThemePreference>(
      AppThemePreferenceNotifier.new,
    );

/// 读写黑夜模式偏好。
class AppThemePreferenceNotifier extends Notifier<AppThemePreference> {
  /// SharedPreferences 键，与 iOS `interface` 同名。
  static const storageKey = 'interface';

  @override
  AppThemePreference build() {
    final preferences = ref.watch(sharedPreferencesProvider);
    return AppThemePreference.fromStorage(preferences.getInt(storageKey) ?? 0);
  }

  /// 记住并立即生效。
  Future<void> setPreference(AppThemePreference preference) async {
    await ref
        .read(sharedPreferencesProvider)
        .setInt(storageKey, preference.storageValue);
    state = preference;
  }
}
