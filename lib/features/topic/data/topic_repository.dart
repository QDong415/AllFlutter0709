import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:all_flutter0709/core/network/page_data.dart';
import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:dio/dio.dart';

class TopicPageResult {
  const TopicPageResult({
    required this.items,
    required this.hasMore,
  });

  final List<TopicModel> items;
  final bool hasMore;
}

class TopicRepository {
  const TopicRepository();

  Future<TopicPageResult> getTopicList({
    required int page,
  }) async {
    final response = await HttpClient.instance.dio.get<Map<String, dynamic>>(
      '/api/topic/getlist',
      queryParameters: {'page': page},
    );

    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }

    final result = ApiResponse<PageData<TopicModel>>.fromJson(
      json,
      (pageJson) => PageData<TopicModel>.fromJson(
        pageJson as Map<String, dynamic>,
        (itemJson) => TopicModel.fromJson(itemJson as Map<String, dynamic>),
      ),
    );

    if (!result.success) {
      throw Exception(result.message.isEmpty ? '请求失败' : result.message);
    }

    final pageData = result.data;
    final items = pageData?.items ?? const <TopicModel>[];
    final hasMore = (pageData?.totalPage ?? 0) > page;
    return TopicPageResult(items: items, hasMore: hasMore);
  }

  Future<void> likeTopic({
    required String tid,
    required bool isLiked,
    required int likeCount,
  }) async {
    final response = await HttpClient.instance.dio.post<Map<String, dynamic>>(
      '/api/topic/like',
      data: <String, dynamic>{
        'dataid': tid,
        'tid': tid,
        'api': 'topic/like',
        'like': isLiked ? '1' : '0',
        'likecount': '$likeCount',
        'type': '1',
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }

    final result = ApiResponse<void>.fromJson(json);
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '点赞失败' : result.message);
    }
  }
}
