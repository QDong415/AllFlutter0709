import 'dart:io';

import 'package:all_flutter0709/core/cloud_storage/cloud_storage_upload_result.dart';
import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:flutter/foundation.dart';
import 'package:qiniu_flutter_sdk/qiniu_flutter_sdk.dart';

/// 七牛云文件上传服务。
///
/// 负责获取上传凭证并用官方 SDK 上传文件，与具体业务（聊天发图、头像等）解耦。
class QiniuUploadService {
  QiniuUploadService();

  static const uploadTokenApi = '/api/qiniu/uploadtoken';
  static const topicVideoTokenApi = '/api/qiniu/topicvideotoken';

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
    final result = await uploadFileResult(
      file: file,
      key: key,
      onProgress: onProgress,
    );
    return result.key;
  }

  /// 上传本地文件并返回完整回调（发动态组 `photoarray` / 视频宽高）。
  ///
  /// [onProgress] 来自 Dio `onSendProgress`。表单直传时往往会一次跳到 1.0，
  /// 发动态进度条不要直接拿它当真实上传进度。
  Future<CloudStorageUploadResult> uploadFileResult({
    required File file,
    required String key,
    String tokenApi = uploadTokenApi,
    Map<String, dynamic>? tokenQueryParameters,
    String? token,
    PutController? putController,
    void Function(double percent)? onProgress,
  }) async {
    final uploadToken =
        (token ??
                await fetchUploadToken(
                  api: tokenApi,
                  queryParameters: tokenQueryParameters,
                ))
            .trim();
    debugPrint('[QiniuUpload] 拿到上传凭证 length=${uploadToken.length}');

    if (!file.existsSync()) {
      throw Exception('上传文件不存在: ${file.path}');
    }

    final fileLength = file.lengthSync();
    if (fileLength <= 0) {
      throw Exception('上传文件为空: ${file.path}');
    }

    final controller = putController ?? PutController();
    if (onProgress != null) {
      controller.addSendProgressListener(onProgress);
    }

    debugPrint(
      '[QiniuUpload] putFile key=$key path=${file.path} size=$fileLength',
    );
    try {
      final response = await _storage.putFile(
        file,
        uploadToken,
        options: PutOptions(key: key, controller: controller),
      );
      final rawData = _normalizeRawData(response.rawData);
      final rawFilename = rawData['filename']?.toString().trim() ?? '';
      final uploadedKey = rawFilename.isNotEmpty
          ? rawFilename
          : (response.key?.toString().trim().isNotEmpty == true
                ? response.key!.toString()
                : key);
      if (rawData['key'] == null && uploadedKey.isNotEmpty) {
        rawData['key'] = uploadedKey;
      }
      if (rawData['filename'] == null && uploadedKey.isNotEmpty) {
        rawData['filename'] = uploadedKey;
      }
      debugPrint(
        '[QiniuUpload] 上传成功 key=$uploadedKey hash=${response.hash} '
        'raw=$rawData',
      );
      return CloudStorageUploadResult(key: uploadedKey, rawData: rawData);
    } catch (error, stackTrace) {
      debugPrint('[QiniuUpload] 上传失败: $error');
      debugPrint('[QiniuUpload] $stackTrace');
      rethrow;
    }
  }

  /// 获取七牛上传凭证。
  Future<String> fetchUploadToken({
    String api = uploadTokenApi,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await HttpClient.instance.get(
        api,
        queryParameters: queryParameters,
      );
      final json = response.data;
      debugPrint('[QiniuUpload] $api 原始响应: $json');
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
        throw Exception(result.message.isEmpty ? '上传凭证获取失败' : result.message);
      }

      final token = result.data?['token']?.toString().trim() ?? '';
      if (token.isEmpty) {
        throw Exception('上传凭证为空');
      }
      return token;
    } catch (error) {
      debugPrint('[QiniuUpload] 获取 $api 失败: $error');
      rethrow;
    }
  }

  Map<String, dynamic> _normalizeRawData(Object? rawData) {
    if (rawData is Map<String, dynamic>) {
      return Map<String, dynamic>.from(rawData);
    }
    if (rawData is Map) {
      return rawData.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
