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
    return _ossEnumFromValue(OssUpload.values, rawValue, (item) => item.value);
  }
}

/// 图片缩略图 URL 拼接规则。
enum OssThumbStyle {
  /// 七牛 `imageView2`。
  qiniu(0),

  /// 阿里云 CDN `image_process`。
  aliyun(1),

  /// CloudFront 图片处理（`width` / `height`）。
  cloudfront(2);

  const OssThumbStyle(this.value);

  /// 服务端下发的枚举值。
  final int value;

  /// 把服务端或缓存里的值转成缩略图规则；无法识别时返回空。
  static OssThumbStyle? fromValue(Object? rawValue) {
    return _ossEnumFromValue(
      OssThumbStyle.values,
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
      case OssThumbStyle.qiniu:
        if (thumbnail) {
          return '?imageView2/1/w/$limitPx/h/$limitPx';
        }
        return '?imageView2/${max ? 3 : 2}/w/$limitPx/h/$limitPx';
      case OssThumbStyle.aliyun:
        if (thumbnail) {
          return '?image_process=crop,w_$limitPx,h_$limitPx,g_center';
        }
        if (max) {
          return '?image_process=resize,s_$limitPx';
        }
        return '?image_process=resize,l_$limitPx';
      case OssThumbStyle.cloudfront:
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

T? _ossEnumFromValue<T>(
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

  static const _ossHttpCacheKey = 'app_config_oss_http';
  static const _ossUploadCacheKey = 'app_config_oss_upload';
  static const _ossThumbStyleCacheKey = 'app_config_oss_thumb_style';

  SharedPreferences? _preferences;
  String? _cachedOssHttp;
  OssUpload? _cachedOssUpload;
  OssThumbStyle? _cachedOssThumbStyle;

  /// 文件访问前缀：优先服务端缓存，其次使用本地环境默认值。
  String get ossHttp => _cachedOssHttp ?? AppEnv.qiniuBaseUrl;

  /// 图片上传目标：优先服务端缓存，缺省为七牛。
  OssUpload get ossUpload => _cachedOssUpload ?? OssUpload.qiniu;

  /// 缩略图拼接规则：优先服务端缓存，缺省为七牛。
  OssThumbStyle get ossThumbStyle =>
      _cachedOssThumbStyle ?? OssThumbStyle.qiniu;

  /// 在 App 启动前恢复本地配置，不执行网络请求。
  void initialize(SharedPreferences preferences) {
    _preferences = preferences;
    _cachedOssHttp = _normalizeOssHttp(preferences.getString(_ossHttpCacheKey));
    _cachedOssUpload = OssUpload.fromValue(
      preferences.getInt(_ossUploadCacheKey),
    );
    _cachedOssThumbStyle = OssThumbStyle.fromValue(
      preferences.getInt(_ossThumbStyleCacheKey),
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

      final ossThumbStyle = OssThumbStyle.fromValue(data['oss_thumb_style']);
      if (ossThumbStyle != null) {
        _cachedOssThumbStyle = ossThumbStyle;
        await preferences.setInt(_ossThumbStyleCacheKey, ossThumbStyle.value);
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
