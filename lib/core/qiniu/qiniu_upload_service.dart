import 'dart:io';

import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qiniu_flutter_sdk/qiniu_flutter_sdk.dart';

/// 七牛云上传服务 Provider。
final qiniuUploadServiceProvider = Provider<QiniuUploadService>((ref) {
  return QiniuUploadService(dio: HttpClient.instance.dio);
});

/// 七牛云文件上传服务。
///
/// 负责获取上传凭证并用官方 SDK 上传文件，与具体业务（聊天发图、头像等）解耦。
class QiniuUploadService {
  QiniuUploadService({required Dio dio}) : _dio = dio;

  static const _uploadTokenApi = '/api/qiniu/uploadtoken';

  final Dio _dio;
  final Storage _storage = Storage();

  /// 上传本地文件到七牛云。
  ///
  /// [key] 为对象存储文件名；[onProgress] 回调进度 0.0~1.0。
  /// 成功后返回实际上传的 key。
  Future<String> uploadFile({
    required File file,
    required String key,
    void Function(double percent)? onProgress,
  }) async {
    final token = await fetchUploadToken();
    debugPrint('[QiniuUpload] 拿到上传凭证 length=${token.length}');

    final putController = PutController();
    if (onProgress != null) {
      putController.addProgressListener(onProgress);
    }

    debugPrint('[QiniuUpload] putFile key=$key path=${file.path}');
    try {
      final response = await _storage.putFile(
        file,
        token,
        options: PutOptions(key: key, controller: putController),
      );
      // 对齐 iTopicX：优先取自定义 returnBody 里的 filename。
      final rawFilename = response.rawData['filename']?.toString().trim() ?? '';
      final uploadedKey = rawFilename.isNotEmpty
          ? rawFilename
          : (response.key?.toString().trim().isNotEmpty == true
                ? response.key!.toString()
                : key);
      debugPrint(
        '[QiniuUpload] 上传成功 key=$uploadedKey hash=${response.hash} '
        'raw=${response.rawData}',
      );
      return uploadedKey;
    } catch (error, stackTrace) {
      debugPrint('[QiniuUpload] 上传失败: $error');
      debugPrint('[QiniuUpload] $stackTrace');
      rethrow;
    }
  }

  /// 获取七牛上传凭证。
  Future<String> fetchUploadToken() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(_uploadTokenApi);
      final json = response.data;
      debugPrint('[QiniuUpload] uploadtoken 原始响应: $json');
      if (json == null) {
        throw Exception('上传凭证为空');
      }

      final result = ApiResponse<Map<String, dynamic>>.fromJson(
        json,
        (dataJson) => (dataJson as Map).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
      if (!result.success) {
        throw Exception(
          result.message.isEmpty ? '上传凭证获取失败' : result.message,
        );
      }

      final token = result.data?['token']?.toString() ?? '';
      if (token.isEmpty) {
        throw Exception('上传凭证为空');
      }
      return token;
    } on DioException catch (error) {
      debugPrint(
        '[QiniuUpload] 获取 uploadtoken 失败 type=${error.type} '
        'status=${error.response?.statusCode} '
        'data=${error.response?.data} message=${error.message}',
      );
      rethrow;
    }
  }
}
