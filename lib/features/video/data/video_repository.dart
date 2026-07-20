import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:all_flutter0709/core/network/page_data.dart';
import 'package:all_flutter0709/features/video/data/models/video_model.dart';

class VideoPageResult {
  const VideoPageResult({required this.items, required this.hasMore});

  final List<VideoModel> items;
  final bool hasMore;
}

class VideoRepository {
  const VideoRepository();

  Future<VideoPageResult> getVideoList({required int page}) async {
    final response = await HttpClient.instance.dio.get<Map<String, dynamic>>(
      '/api/video/getlist',
      queryParameters: {'page': page},
    );

    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }

    final result = ApiResponse<PageData<VideoModel>>.fromJson(
      json,
      (pageJson) => PageData<VideoModel>.fromJson(
        pageJson as Map<String, dynamic>,
        (itemJson) => VideoModel.fromJson(itemJson as Map<String, dynamic>),
      ),
    );

    if (!result.success) {
      throw Exception(result.message.isEmpty ? '请求失败' : result.message);
    }

    final pageData = result.data;
    final items = pageData?.items ?? const <VideoModel>[];
    final hasMore = (pageData?.totalPage ?? 0) > page;
    return VideoPageResult(items: items, hasMore: hasMore);
  }
}
