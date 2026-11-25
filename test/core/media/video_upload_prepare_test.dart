import 'package:all_flutter0709/core/media/video_upload_prepare.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('长边超过 1280 才压缩，未知宽高也压缩', () {
    expect(VideoUploadPrepare.needsCompress(width: 1920, height: 1080), isTrue);
    expect(VideoUploadPrepare.needsCompress(width: 1080, height: 1920), isTrue);
    expect(VideoUploadPrepare.needsCompress(width: 1280, height: 720), isFalse);
    expect(VideoUploadPrepare.needsCompress(width: 720, height: 1280), isFalse);
    expect(VideoUploadPrepare.needsCompress(width: 0, height: 0), isTrue);
    expect(VideoUploadPrepare.needsCompress(width: 1920, height: 0), isTrue);
  });

  test('压缩失败时原片不超过 100MB 才发送', () {
    const limit = VideoUploadPrepare.maxOriginalBytes;
    expect(limit, 100 * 1024 * 1024);
    expect(VideoUploadPrepare.canSendOriginal(limit), isTrue);
    expect(VideoUploadPrepare.canSendOriginal(limit + 1), isFalse);
    expect(VideoUploadPrepare.canSendOriginal(0), isFalse);
  });
}
