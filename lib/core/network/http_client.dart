import 'package:all_flutter0709/core/network/app_env.dart';
import 'package:all_flutter0709/core/network/request_sign.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// 全局 HTTP 客户端：统一 baseUrl、超时、日志，并按 Buddy 规则附带验签参数。
///
/// Repository 请调用 [get] / [post]，不要直接访问 Dio。
class HttpClient {
  HttpClient._();

  static final HttpClient instance = HttpClient._();

  static const _deviceIdKey = 'dev_id';

  final Logger _logger = Logger();
  String _userId = '';
  String _deviceId = '';
  String _clientVersion = '0';

  late final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: AppEnv.apiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            responseType: ResponseType.json,
            headers: const {'Content-Type': 'application/json'},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              _appendSign(options);
              _logger.d(
                '[HTTP] ${options.method} ${options.uri} '
                'data=${_formatRequestData(options.data)}',
              );
              handler.next(options);
            },
            onResponse: (response, handler) {
              _logger.d(
                '[HTTP] ${response.statusCode} ${response.realUri} '
                'data=${response.data}',
              );
              handler.next(response);
            },
            onError: (error, handler) {
              _logger.e(
                '[HTTP] ${error.message} '
                'status=${error.response?.statusCode} '
                'response=${error.response?.data} '
                'data=${_formatRequestData(error.requestOptions.data)}',
              );
              handler.next(error);
            },
          ),
        );

  /// 读取或生成设备号，并缓存版本号。应在发起业务请求前调用。
  Future<void> prepare(SharedPreferences preferences) async {
    final savedDeviceId = preferences.getString(_deviceIdKey)?.trim() ?? '';
    if (savedDeviceId.isEmpty) {
      _deviceId = const Uuid().v4();
      await preferences.setString(_deviceIdKey, _deviceId);
    } else {
      _deviceId = savedDeviceId;
    }

    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      if (version.isNotEmpty) {
        _clientVersion = version;
      }
    } catch (error) {
      _logger.w('[HTTP] 读取版本号失败，clientver 使用 0: $error');
    }
  }

  /// 更新当前登录用户 id。未登录时请求里的 `userid` 为空字符串。
  void updateUserId(String? value) {
    final nextUserId = value?.trim();
    _userId = nextUserId == null || nextUserId.isEmpty ? '' : nextUserId;
  }

  /// GET 请求。
  Future<Response<Map<String, dynamic>>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
    );
  }

  /// 把 Dio / 业务异常转成可读文案，避免把整段 HTML 500 页丢到进度条上。
  String describeError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
      final status = error.response?.statusCode;
      if (status != null) {
        return '服务器错误($status)';
      }
      return error.message ?? error.toString();
    }
    return error.toString().replaceFirst(RegExp(r'^Exception: '), '');
  }

  /// POST 请求；默认 `application/x-www-form-urlencoded`（与现有接口一致）。
  Future<Response<Map<String, dynamic>>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool formUrlEncoded = true,
    Duration? sendTimeout,
    Duration? receiveTimeout,
  }) {
    return _dio.post<Map<String, dynamic>>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(
        contentType: formUrlEncoded
            ? Headers.formUrlEncodedContentType
            : Headers.jsonContentType,
        sendTimeout: sendTimeout,
        receiveTimeout: receiveTimeout,
      ),
    );
  }

  Object? _formatRequestData(Object? data) {
    if (data is FormData) {
      return <String, Object?>{
        for (final field in data.fields) field.key: field.value,
        for (final file in data.files)
          file.key: 'MultipartFile(${file.value.filename})',
      };
    }
    return data;
  }

  /// GET 签在 query 上；POST 签在 body 上，并清掉 query。
  ///
  /// PHP 以后若开启校验，用的是 `empty($_GET) ? $_POST : $_GET`，
  /// 同一请求不能同时带 query 和 body。
  void _appendSign(RequestOptions options) {
    final isGet = options.method.toUpperCase() == 'GET';
    final fieldMap = <String, String>{};
    if (isGet) {
      fieldMap.addAll(_asStringMap(options.queryParameters));
    } else {
      fieldMap.addAll(_asStringMap(options.queryParameters));
      final data = options.data;
      if (data is FormData) {
        fieldMap.addAll(_asStringMapFromFormData(data));
      } else {
        fieldMap.addAll(_asStringMap(data));
      }
    }

    fieldMap.addAll(_commonFieldMap());
    fieldMap['sig'] = RequestSign.sign(fieldMap);

    if (isGet) {
      options.queryParameters
        ..clear()
        ..addAll(fieldMap);
      return;
    }

    options.queryParameters.clear();
    final data = options.data;
    if (data is FormData) {
      data.fields.clear();
      fieldMap.forEach((key, value) {
        data.fields.add(MapEntry(key, value));
      });
      return;
    }
    options.data = fieldMap;
  }

  Map<String, String> _commonFieldMap() {
    return <String, String>{
      'userid': _userId,
      'ts': '${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
      'os': _osName(),
      'clientver': _clientVersion,
      'deviceid': _deviceId,
    };
  }

  String _osName() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return defaultTargetPlatform.name;
    }
  }

  Map<String, String> _asStringMap(Object? data) {
    if (data is! Map) {
      return <String, String>{};
    }
    return <String, String>{
      for (final entry in data.entries)
        entry.key.toString(): _asSignValue(entry.value),
    };
  }

  Map<String, String> _asStringMapFromFormData(FormData data) {
    return <String, String>{
      for (final field in data.fields) field.key: field.value,
    };
  }

  String _asSignValue(Object? value) {
    if (value == null) {
      return '';
    }
    return value.toString();
  }
}
