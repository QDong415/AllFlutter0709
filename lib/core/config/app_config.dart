import 'package:all_flutter0709/core/network/app_env.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 管理服务端下发的全局配置，并在网络不可用时回退到本地缓存或默认值。
class AppConfig {
  AppConfig._();

  static final AppConfig instance = AppConfig._();

  static const _ossHttpCacheKey = 'app_config_oss_http';

  SharedPreferences? _preferences;
  String? _cachedOssHttp;

  /// 文件访问前缀：优先服务端缓存，其次使用本地环境默认值。
  String get ossHttp => _cachedOssHttp ?? AppEnv.qiniuBaseUrl;

  /// 在 App 启动前恢复本地配置，不执行网络请求。
  void initialize(SharedPreferences preferences) {
    _preferences = preferences;
    _cachedOssHttp = _normalizeOssHttp(preferences.getString(_ossHttpCacheKey));
  }

  /// 从服务端刷新配置；失败或返回空值时保留当前配置。
  Future<void> refresh() async {
    final preferences = _preferences;
    if (preferences == null) {
      throw StateError('AppConfig 尚未初始化');
    }

    try {
      final response = await HttpClient.instance.get('/api/base/config');
      final responseMap = response.data;
      final code = (responseMap?['code'] as num?)?.toInt() ?? 0;
      final data = responseMap?['data'];
      final ossHttp = data is Map
          ? _normalizeOssHttp(data['oss_http']?.toString())
          : null;
      if (code != 1 || ossHttp == null) {
        return;
      }

      _cachedOssHttp = ossHttp;
      await preferences.setString(_ossHttpCacheKey, ossHttp);
    } catch (error) {
      debugPrint('[AppConfig] 刷新配置失败，继续使用本地配置: $error');
    }
  }

  String? _normalizeOssHttp(String? value) {
    final trimmedValue = value?.trim() ?? '';
    if (trimmedValue.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(trimmedValue);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    return trimmedValue.endsWith('/') ? trimmedValue : '$trimmedValue/';
  }
}
