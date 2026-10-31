import 'dart:io';

import 'package:all_flutter0709/core/cloud_storage/cloud_storage_upload_result.dart';
import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 亚马逊 S3：向 PHP 要预签名后 PUT。
class S3UploadService {
  S3UploadService();

  static const uploadTokenApi = '/api/s3/uploadtoken';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(minutes: 10),
      receiveTimeout: const Duration(minutes: 2),
      followRedirects: false,
    ),
  );

  Future<CloudStorageUploadResult> uploadFileResult({
    required File file,
    required String key,
    CancelToken? cancelToken,
    void Function(double percent)? onProgress,
  }) async {
    if (!file.existsSync()) {
      throw Exception('上传文件不存在: ${file.path}');
    }
    final fileLength = file.lengthSync();
    if (fileLength <= 0) {
      throw Exception('上传文件为空: ${file.path}');
    }

    final url = await _fetchPresignUrl(key);
    if (cancelToken?.isCancelled == true) {
      throw const CloudStorageUploadCancelled();
    }
    debugPrint('[S3Upload] PUT key=$key size=$fileLength');
    try {
      await _dio.putUri(
        Uri.parse(url),
        data: file.openRead(),
        cancelToken: cancelToken,
        options: Options(
          headers: <String, dynamic>{Headers.contentLengthHeader: fileLength},
          contentType: 'application/octet-stream',
          responseType: ResponseType.bytes,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 300,
        ),
        onSendProgress: (sent, total) {
          if (onProgress == null) {
            return;
          }
          final length = total > 0 ? total : fileLength;
          if (length <= 0) {
            return;
          }
          onProgress((sent / length).clamp(0.0, 1.0));
        },
      );
      debugPrint('[S3Upload] 上传成功 key=$key');
      return CloudStorageUploadResult(
        key: key,
        rawData: <String, dynamic>{'filename': key, 'key': key},
      );
    } on DioException catch (error) {
      if (error.type == DioExceptionType.cancel ||
          cancelToken?.isCancelled == true) {
        throw const CloudStorageUploadCancelled();
      }
      debugPrint(
        '[S3Upload] 上传失败 status=${error.response?.statusCode} $error',
      );
      final message = HttpClient.instance.describeError(error);
      throw Exception(message.isEmpty ? 'S3 上传失败' : message);
    }
  }

  Future<String> _fetchPresignUrl(String key) async {
    try {
      final response = await HttpClient.instance.get(
        uploadTokenApi,
        queryParameters: <String, dynamic>{'key': key},
      );
      final json = response.data;
      if (json == null) {
        throw Exception('S3 预签名为空');
      }
      final result = ApiResponse<Map<String, dynamic>>.fromJson(
        json,
        (dataJson) => (dataJson as Map).map(
          (mapKey, value) => MapEntry(mapKey.toString(), value),
        ),
      );
      if (!result.success) {
        throw Exception(result.message.isEmpty ? 'S3 预签名失败' : result.message);
      }
      final url = result.data?['url']?.toString().trim() ?? '';
      if (url.isEmpty) {
        throw Exception('S3 预签名为空');
      }
      return url;
    } catch (error) {
      debugPrint('[S3Upload] 获取 $uploadTokenApi 失败: $error');
      rethrow;
    }
  }
}
