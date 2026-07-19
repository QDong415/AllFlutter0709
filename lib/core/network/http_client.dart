import 'package:all_flutter0709/core/network/app_env.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class HttpClient {
  HttpClient._();

  static final HttpClient instance = HttpClient._();

  final Logger _logger = Logger();
  String? _userId;

  void updateUserId(String? value) {
    final nextUserId = value?.trim();
    _userId = nextUserId == null || nextUserId.isEmpty ? null : nextUserId;
  }

  late final Dio dio =
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
              _logger.d('[HTTP] ${options.method} ${options.uri}');
              handler.next(options);
            },
            onResponse: (response, handler) {
              _logger.d('[HTTP] ${response.statusCode} ${response.realUri}');
              handler.next(response);
            },
            onError: (error, handler) {
              _logger.e('[HTTP] ${error.message}');
              handler.next(error);
            },
          ),
        );

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
