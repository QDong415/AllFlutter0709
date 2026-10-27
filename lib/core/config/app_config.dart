import 'package:all_flutter0709/core/network/app_env.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 图片上传目标。
enum OssUpload {
  /// 上传到七牛。
  qiniu(0),

  /// 上传到亚马逊。
  aws(1);

  const OssUpload(this.value);

  /// 服务端下发的枚举值。
  final int value;

  /// 把服务端或缓存里的值转成上传目标；无法识别时返回空。
  static OssUpload? fromValue(Object? rawValue) {
    final value = switch (rawValue) {
      final num number => number.toInt(),
      final String text => int.tryParse(text.trim()),
      _ => null,
    };
    for (final target in OssUpload.values) {
      if (target.value == value) {
        return target;
      }
    }
    return null;
  }
}

/// 管理服务端下发的全局配置，并在网络不可用时回退到本地缓存或默认值。
class AppConfig {
  AppConfig._();

  static final AppConfig instance = AppConfig._();

  static const _ossHttpCacheKey = 'app_config_oss_http';
  static const _ossUploadCacheKey = 'app_config_oss_upload';

  SharedPreferences? _preferences;
  String? _cachedOssHttp;
  OssUpload? _cachedOssUpload;

  /// 文件访问前缀：优先服务端缓存，其次使用本地环境默认值。
  String get ossHttp => _cachedOssHttp ?? AppEnv.qiniuBaseUrl;

  /// 图片上传目标：优先服务端缓存，缺省为七牛。
  OssUpload get ossUpload => _cachedOssUpload ?? OssUpload.qiniu;

  /// 在 App 启动前恢复本地配置，不执行网络请求。
  void initialize(SharedPreferences preferences) {
    _preferences = preferences;
    _cachedOssHttp = _normalizeOssHttp(preferences.getString(_ossHttpCacheKey));
    _cachedOssUpload = OssUpload.fromValue(
      preferences.getInt(_ossUploadCacheKey),
    );
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
      if (code != 1 || data is! Map) {
        return;
      }

      final ossHttp = _normalizeOssHttp(data['oss_http']?.toString());
      if (ossHttp != null) {
        _cachedOssHttp = ossHttp;
        await preferences.setString(_ossHttpCacheKey, ossHttp);
      }

      final ossUpload = OssUpload.fromValue(data['oss_upload']);
      if (ossUpload != null) {
        _cachedOssUpload = ossUpload;
        await preferences.setInt(_ossUploadCacheKey, ossUpload.value);
      }
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
