import 'package:all_flutter0709/core/network/app_env.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 对象存储上传目标。
enum CloudStorage {
  /// 上传到七牛。
  qiniu(0),

  /// 上传到亚马逊 S3。
  s3(1);

  const CloudStorage(this.value);

  /// 服务端下发的枚举值。
  final int value;

  /// 把服务端或缓存里的值转成上传目标；无法识别时返回空。
  static CloudStorage? fromValue(Object? rawValue) {
    return _enumFromValue(CloudStorage.values, rawValue, (item) => item.value);
  }
}

/// 图片缩略图 URL 拼接规则。
enum CloudStorageThumbStyle {
  /// 七牛 `imageView2`。
  qiniu(0),

  /// 阿里云 CDN `image_process`（不是阿里云 OSS）。
  aliyun(1),

  /// CloudFront 图片处理（`width` / `height`）。
  cloudfront(2);

  const CloudStorageThumbStyle(this.value);

  /// 服务端下发的枚举值。
  final int value;

  /// 把服务端或缓存里的值转成缩略图规则；无法识别时返回空。
  static CloudStorageThumbStyle? fromValue(Object? rawValue) {
    return _enumFromValue(
      CloudStorageThumbStyle.values,
      rawValue,
      (item) => item.value,
    );
  }

  /// 生成缩略图查询串，调用方负责跳过 GIF 和原图。
  String query({
    required int limitPx,
    required bool max,
    required bool thumbnail,
  }) {
    switch (this) {
      case CloudStorageThumbStyle.qiniu:
        if (thumbnail) {
          return '?imageView2/1/w/$limitPx/h/$limitPx';
        }
        return '?imageView2/${max ? 3 : 2}/w/$limitPx/h/$limitPx';
      case CloudStorageThumbStyle.aliyun:
        if (thumbnail) {
          return '?image_process=crop,w_$limitPx,h_$limitPx,g_center';
        }
        if (max) {
          return '?image_process=resize,s_$limitPx';
        }
        return '?image_process=resize,l_$limitPx';
      case CloudStorageThumbStyle.cloudfront:
        if (thumbnail) {
          return '?width=$limitPx&height=$limitPx&fit=cover';
        }
        if (max) {
          return '?width=$limitPx&height=$limitPx&fit=outside';
        }
        return '?width=$limitPx&height=$limitPx&fit=inside';
    }
  }
}

T? _enumFromValue<T>(
  Iterable<T> values,
  Object? rawValue,
  int Function(T item) readValue,
) {
  final value = switch (rawValue) {
    final num number => number.toInt(),
    final String text => int.tryParse(text.trim()),
    _ => null,
  };
  for (final target in values) {
    if (readValue(target) == value) {
      return target;
    }
  }
  return null;
}

/// 管理服务端下发的全局配置，并在网络不可用时回退到本地缓存或默认值。
class AppConfig {
  AppConfig._();

  static final AppConfig instance = AppConfig._();

  static const _httpCacheKey = 'app_config_cloud_storage_http';
  static const _storageCacheKey = 'app_config_cloud_storage';
  static const _thumbStyleCacheKey = 'app_config_cloud_storage_thumb_style';

  SharedPreferences? _preferences;
  String? _cachedHttp;
  CloudStorage? _cachedStorage;
  CloudStorageThumbStyle? _cachedThumbStyle;

  /// 文件访问前缀，跟服务端 `oss_http`。
  String get cloudStorageHttp => _cachedHttp ?? AppEnv.qiniuBaseUrl;

  /// 上传目标，跟服务端 `oss_upload`。
  CloudStorage get cloudStorage => _cachedStorage ?? CloudStorage.qiniu;

  /// 缩略图拼接规则，跟服务端 `oss_thumb_style`。
  CloudStorageThumbStyle get cloudStorageThumbStyle =>
      _cachedThumbStyle ?? CloudStorageThumbStyle.qiniu;

  /// 在 App 启动前恢复本地配置，不执行网络请求。
  void initialize(SharedPreferences preferences) {
    _preferences = preferences;
    _cachedHttp = _normalizeHttp(
      preferences.getString(_httpCacheKey) ??
          preferences.getString('app_config_oss_http'),
    );
    _cachedStorage = CloudStorage.fromValue(
      preferences.getInt(_storageCacheKey) ??
          preferences.getInt('app_config_oss_upload'),
    );
    _cachedThumbStyle = CloudStorageThumbStyle.fromValue(
      preferences.getInt(_thumbStyleCacheKey) ??
          preferences.getInt('app_config_oss_thumb_style'),
    );
    // 以前设置页可选上传目标，本地覆盖作废，一律跟服务端。
    preferences.remove('app_config_cloud_storage_override');
    preferences.remove('app_config_oss_upload_override');
  }

  /// 从服务端刷新配置；失败或返回空值时保留当前配置。
  ///
  /// 仍读 `oss_http` / `oss_upload` / `oss_thumb_style`，兼容线上旧包和现网接口。
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

      final http = _normalizeHttp(data['oss_http']?.toString());
      if (http != null) {
        _cachedHttp = http;
        await preferences.setString(_httpCacheKey, http);
      }

      final storage = CloudStorage.fromValue(data['oss_upload']);
      if (storage != null) {
        _cachedStorage = storage;
        await preferences.setInt(_storageCacheKey, storage.value);
      }

      final thumbStyle = CloudStorageThumbStyle.fromValue(
        data['oss_thumb_style'],
      );
      if (thumbStyle != null) {
        _cachedThumbStyle = thumbStyle;
        await preferences.setInt(_thumbStyleCacheKey, thumbStyle.value);
      }
    } catch (error) {
      debugPrint('[AppConfig] 刷新配置失败，继续使用本地配置: $error');
    }
  }

  String? _normalizeHttp(String? value) {
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
