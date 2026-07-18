import 'package:all_flutter0709/core/network/app_env.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class HttpClient {
  HttpClient._();

  static final HttpClient instance = HttpClient._();

  final Logger _logger = Logger();

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
}
