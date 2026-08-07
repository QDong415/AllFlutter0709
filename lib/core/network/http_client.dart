import 'package:all_flutter0709/core/network/app_env.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// 全局 HTTP 客户端：统一 baseUrl、超时、日志与 userid 注入。
///
/// Repository 请调用 [get] / [post]，不要直接访问 Dio。
class HttpClient {
  HttpClient._();

  static final HttpClient instance = HttpClient._();

  final Logger _logger = Logger();
  String? _userId;

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
              _appendUserId(options);
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
                'data=${_formatRequestData(error.requestOptions.data)}',
              );
              handler.next(error);
            },
          ),
        );

  /// 更新当前登录用户 id（请求拦截器会自动附带 `userid`）。
  void updateUserId(String? value) {
    final nextUserId = value?.trim();
    _userId = nextUserId == null || nextUserId.isEmpty ? null : nextUserId;
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

  /// POST 请求；默认 `application/x-www-form-urlencoded`（与现有接口一致）。
  Future<Response<Map<String, dynamic>>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool formUrlEncoded = true,
  }) {
    return _dio.post<Map<String, dynamic>>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: formUrlEncoded
          ? Options(contentType: Headers.formUrlEncodedContentType)
          : null,
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

  void _appendUserId(RequestOptions options) {
    final userId = _userId ?? '';
    if (userId.isEmpty) {
      return;
    }

    options.queryParameters.putIfAbsent('userid', () => userId);

    final data = options.data;
    if (data == null) {
      options.data = <String, dynamic>{'userid': userId};
      return;
    }

    if (data is Map<String, dynamic>) {
      data.putIfAbsent('userid', () => userId);
      return;
    }

    if (data is Map) {
      data.putIfAbsent('userid', () => userId);
      return;
    }

    if (data is FormData) {
      final hasUserId = data.fields.any((field) => field.key == 'userid');
      if (!hasUserId) {
        data.fields.add(MapEntry('userid', userId));
      }
    }
  }
}
