/// 用户取消了上传。
class CloudStorageUploadCancelled implements Exception {
  const CloudStorageUploadCancelled();
}

/// 七牛或 S3 上传成功后的统一结果。
class CloudStorageUploadResult {
  const CloudStorageUploadResult({required this.key, required this.rawData});

  /// 实际上传的对象名。
  final String key;

  /// 七牛 returnBody，或 S3 侧补的 filename/key。
  final Map<String, dynamic> rawData;

  String get widthText => rawData['width']?.toString().trim() ?? '';

  String get heightText => rawData['height']?.toString().trim() ?? '';

  bool get hasSize => widthText.isNotEmpty && heightText.isNotEmpty;

  /// 对齐 Android 发动态 `photoarray`：只要 filename / width / height。
  Map<String, String> toTopicPhotoJson({(int, int)? fallbackSize}) {
    var width = widthText;
    var height = heightText;
    if (!hasSize && fallbackSize != null) {
      width = '${fallbackSize.$1}';
      height = '${fallbackSize.$2}';
    }
    return <String, String>{
      'filename': key,
      'width': width,
      'height': height,
    };
  }
}
