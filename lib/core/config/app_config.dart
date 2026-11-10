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
  static const _videoHttpCacheKey = 'app_config_cloud_storage_video_http';
  static const _storageCacheKey = 'app_config_cloud_storage';
  static const _thumbStyleCacheKey = 'app_config_cloud_storage_thumb_style';
  static const _imageUploadMaxMemoryCacheKey =
      'app_config_image_upload_max_memory';
  static const _allowTopicSubmitCacheKey = 'app_config_allow_topic_submit';
  static const _allowTopicCommentCacheKey = 'app_config_allow_topic_comment';
  static const _allowVideoSubmitCacheKey = 'app_config_allow_video_submit';
  static const _allowChatFemaleToFemaleCacheKey =
      'app_config_allow_chat_fetofe';
  static const _allowChatImageCacheKey = 'app_config_allow_chat_image';
  static const _allowChatCountCacheKey = 'app_config_allow_chat_count';
  static const _coinScaleCacheKey = 'app_config_coin_scale';
  static const _appReviewingCacheKey = 'app_config_app_reviewing';

  /// 没拉到配置时的发图上限，单位 MB。
  static const defaultImageUploadMaxMemoryMb = 6;

  /// Buddy 默认：0 表示非会员需 VIP 才能发话题（配合客户端 `shouldBeLimit`）。
  static const defaultAllowTopicSubmit = 0;

  static const defaultAllowTopicComment = 0;
  static const defaultAllowVideoSubmit = 0;

  /// 1 允许女对女私聊；0 非会员不可给女性发消息。
  static const defaultAllowChatFemaleToFemale = 0;

  /// 1 允许非会员发图；0 需 VIP。
  static const defaultAllowChatImage = 0;

  static const defaultAllowChatCount = 30;
  static const defaultCoinScale = 10;

  SharedPreferences? _preferences;
  String? _cachedHttp;
  String? _cachedVideoHttp;
  CloudStorage? _cachedStorage;
  CloudStorageThumbStyle? _cachedThumbStyle;
  int? _cachedImageUploadMaxMemoryMb;
  int? _cachedAllowTopicSubmit;
  int? _cachedAllowTopicComment;
  int? _cachedAllowVideoSubmit;
  int? _cachedAllowChatFemaleToFemale;
  int? _cachedAllowChatImage;
  int? _cachedAllowChatCount;
  int? _cachedCoinScale;
  bool _cachedAppReviewing = false;

  /// 文件访问前缀，跟服务端 `oss_http`。
  String get cloudStorageHttp => _cachedHttp ?? AppEnv.cloudFrontBaseUrl;

  /// 视频播放前缀，跟服务端 `oss_video_http`。
  ///
  /// S3 时 DIT 域名播不了视频，用阿里云 CDN；七牛或未下发时回退 [cloudStorageHttp]。
  String get cloudStorageVideoHttp {
    final cached = _cachedVideoHttp;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    if (cloudStorage == CloudStorage.s3) {
      return AppEnv.s3VideoBaseUrl;
    }
    return cloudStorageHttp;
  }

  /// 上传目标，跟服务端 `oss_upload`。
  CloudStorage get cloudStorage => _cachedStorage ?? CloudStorage.s3;

  /// 缩略图拼接规则，跟服务端 `oss_thumb_style`。
  CloudStorageThumbStyle get cloudStorageThumbStyle =>
      _cachedThumbStyle ?? CloudStorageThumbStyle.cloudfront;

  /// 发图压缩上限，单位 MB。跟服务端 `image_upload_max_memory`。`<= 0` 不压缩。
  int get imageUploadMaxMemoryMb =>
      _cachedImageUploadMaxMemoryMb ?? defaultImageUploadMaxMemoryMb;

  /// 非会员是否可直接发话题。0 需 VIP（对齐 Buddy）。
  int get allowTopicSubmit =>
      _cachedAllowTopicSubmit ?? defaultAllowTopicSubmit;

  int get allowTopicComment =>
      _cachedAllowTopicComment ?? defaultAllowTopicComment;

  int get allowVideoSubmit =>
      _cachedAllowVideoSubmit ?? defaultAllowVideoSubmit;

  /// 女用户对女性发私聊。字段名与服务端 `allow_chat_fetofe` 一致。
  int get allowChatFemaleToFemale =>
      _cachedAllowChatFemaleToFemale ?? defaultAllowChatFemaleToFemale;

  /// 非会员是否可发聊天图片。0 需 VIP。
  int get allowChatImage => _cachedAllowChatImage ?? defaultAllowChatImage;

  /// 非会员每日聊天条数上限。
  int get allowChatCount => _cachedAllowChatCount ?? defaultAllowChatCount;

  int get coinScale => _cachedCoinScale ?? defaultCoinScale;

  /// 审核期标记。为 true 时「我的」隐藏充值会员、充值金币、魅力提现。
  bool get appReviewing => _cachedAppReviewing;

  /// 把 `app_reviewing` 转成是否审核中。`true`、`1`、`"1"` 为审核中，缺省为否。
  static bool isReviewingValue(Object? rawValue) {
    return switch (rawValue) {
      true => true,
      final num number => number != 0,
      final String text =>
        text.trim() == '1' || text.trim().toLowerCase() == 'true',
      _ => false,
    };
  }

  /// 更新审核开关，并写入本地缓存，供下次冷启动先显示。
  void setAppReviewing(bool reviewing) {
    _cachedAppReviewing = reviewing;
    _preferences?.setBool(_appReviewingCacheKey, reviewing);
  }

  /// 在 App 启动前恢复本地配置，不执行网络请求。
  void initialize(SharedPreferences preferences) {
    _preferences = preferences;
    _cachedHttp = _normalizeHttp(
      preferences.getString(_httpCacheKey) ??
          preferences.getString('app_config_oss_http'),
    );
    _cachedVideoHttp = _normalizeHttp(
      preferences.getString(_videoHttpCacheKey) ??
          preferences.getString('app_config_oss_video_http'),
    );
    _cachedStorage = CloudStorage.fromValue(
      preferences.getInt(_storageCacheKey) ??
          preferences.getInt('app_config_oss_upload'),
    );
    _cachedThumbStyle = CloudStorageThumbStyle.fromValue(
      preferences.getInt(_thumbStyleCacheKey) ??
          preferences.getInt('app_config_oss_thumb_style'),
    );
    _cachedImageUploadMaxMemoryMb = preferences.getInt(
      _imageUploadMaxMemoryCacheKey,
    );
    _cachedAllowTopicSubmit = preferences.getInt(_allowTopicSubmitCacheKey);
    _cachedAllowTopicComment = preferences.getInt(_allowTopicCommentCacheKey);
    _cachedAllowVideoSubmit = preferences.getInt(_allowVideoSubmitCacheKey);
    _cachedAllowChatFemaleToFemale = preferences.getInt(
      _allowChatFemaleToFemaleCacheKey,
    );
    _cachedAllowChatImage = preferences.getInt(_allowChatImageCacheKey);
    _cachedAllowChatCount = preferences.getInt(_allowChatCountCacheKey);
    _cachedCoinScale = preferences.getInt(_coinScaleCacheKey);
    _cachedAppReviewing =
        preferences.getBool(_appReviewingCacheKey) ?? false;
    // 以前设置页可选上传目标，本地覆盖作废，一律跟服务端。
    preferences.remove('app_config_cloud_storage_override');
    preferences.remove('app_config_oss_upload_override');
  }

  /// 从服务端刷新配置；失败或返回空值时保留当前配置。
  ///
  /// 仍读 `oss_http` / `oss_video_http` / `oss_upload` / `oss_thumb_style` 等。
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

      final videoHttp = _normalizeHttp(data['oss_video_http']?.toString());
      if (videoHttp != null) {
        _cachedVideoHttp = videoHttp;
        await preferences.setString(_videoHttpCacheKey, videoHttp);
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

      final maxMemoryMb = _readInt(data['image_upload_max_memory']);
      if (maxMemoryMb != null) {
        _cachedImageUploadMaxMemoryMb = maxMemoryMb;
        await preferences.setInt(_imageUploadMaxMemoryCacheKey, maxMemoryMb);
      }

      await _cacheIntPreference(
        preferences: preferences,
        rawValue: data['allow_topic_submit'],
        cacheKey: _allowTopicSubmitCacheKey,
        onCached: (value) => _cachedAllowTopicSubmit = value,
      );
      await _cacheIntPreference(
        preferences: preferences,
        rawValue: data['allow_topic_comment'],
        cacheKey: _allowTopicCommentCacheKey,
        onCached: (value) => _cachedAllowTopicComment = value,
      );
      await _cacheIntPreference(
        preferences: preferences,
        rawValue: data['allow_video_submit'],
        cacheKey: _allowVideoSubmitCacheKey,
        onCached: (value) => _cachedAllowVideoSubmit = value,
      );
      await _cacheIntPreference(
        preferences: preferences,
        rawValue: data['allow_chat_fetofe'],
        cacheKey: _allowChatFemaleToFemaleCacheKey,
        onCached: (value) => _cachedAllowChatFemaleToFemale = value,
      );
      await _cacheIntPreference(
        preferences: preferences,
        rawValue: data['allow_chat_image'],
        cacheKey: _allowChatImageCacheKey,
        onCached: (value) => _cachedAllowChatImage = value,
      );
      await _cacheIntPreference(
        preferences: preferences,
        rawValue: data['allow_chat_count'],
        cacheKey: _allowChatCountCacheKey,
        onCached: (value) => _cachedAllowChatCount = value,
      );
      await _cacheIntPreference(
        preferences: preferences,
        rawValue: data['coin_scale'],
        cacheKey: _coinScaleCacheKey,
        onCached: (value) => _cachedCoinScale = value,
      );
      setAppReviewing(isReviewingValue(data['app_reviewing']));
    } catch (error) {
      debugPrint('[AppConfig] 刷新配置失败，继续使用本地配置: $error');
    }
  }

  int? _readInt(Object? rawValue) {
    return switch (rawValue) {
      final num number => number.toInt(),
      final String text => int.tryParse(text.trim()),
      _ => null,
    };
  }

  Future<void> _cacheIntPreference({
    required SharedPreferences preferences,
    required Object? rawValue,
    required String cacheKey,
    required void Function(int value) onCached,
  }) async {
    final value = _readInt(rawValue);
    if (value == null) {
      return;
    }
    onCached(value);
    await preferences.setInt(cacheKey, value);
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
