import 'dart:io';

import 'package:all_flutter0709/core/cloud_storage/cloud_storage_upload_result.dart';
import 'package:all_flutter0709/core/cloud_storage/s3_upload_service.dart';
import 'package:all_flutter0709/core/config/app_config.dart';
import 'package:all_flutter0709/core/qiniu/qiniu_upload_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qiniu_flutter_sdk/qiniu_flutter_sdk.dart';

/// 七牛 / S3 统一上传入口。
final cloudStorageServiceProvider = Provider<CloudStorageService>((ref) {
  return CloudStorageService();
});

/// 按当前 [CloudStorage] 分流；内部自己持有七牛和 S3 实现。
class CloudStorageService {
  CloudStorageService()
    : _qiniu = QiniuUploadService(),
      _s3 = S3UploadService();

  final QiniuUploadService _qiniu;
  final S3UploadService _s3;

  Future<String> fetchQiniuUploadToken({
    String api = QiniuUploadService.uploadTokenApi,
    Map<String, dynamic>? queryParameters,
  }) {
    return _qiniu.fetchUploadToken(api: api, queryParameters: queryParameters);
  }

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

  Future<CloudStorageUploadResult> uploadFileResult({
    required File file,
    required String key,
    String tokenApi = QiniuUploadService.uploadTokenApi,
    Map<String, dynamic>? tokenQueryParameters,
    String? token,
    PutController? putController,
    CancelToken? cancelToken,
    void Function(double percent)? onProgress,
  }) {
    if (AppConfig.instance.cloudStorage == CloudStorage.s3) {
      return _s3.uploadFileResult(
        file: file,
        key: key,
        cancelToken: cancelToken,
        onProgress: onProgress,
      );
    }
    return _qiniu.uploadFileResult(
      file: file,
      key: key,
      tokenApi: tokenApi,
      tokenQueryParameters: tokenQueryParameters,
      token: token,
      putController: putController,
      onProgress: onProgress,
    );
  }
}
