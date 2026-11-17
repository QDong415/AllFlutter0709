/// 大图预览「保存到相册」的数据来源。
sealed class PreviewSaveSource {
  const PreviewSaveSource();
}

/// 从网络地址下载后保存。
final class PreviewSaveFromUrl extends PreviewSaveSource {
  const PreviewSaveFromUrl(this.url);

  final String url;
}

/// 从本机已有文件复制到相册。
final class PreviewSaveFromLocalPath extends PreviewSaveSource {
  const PreviewSaveFromLocalPath(this.path);

  final String path;
}
