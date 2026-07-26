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

  Future<TopicModel> getTopicDetail({required String tid}) async {
    final response = await HttpClient.instance.dio.get<Map<String, dynamic>>(
      '/api/topic/detail',
      queryParameters: {'tid': tid},
    );

    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }

    final result = ApiResponse<TopicModel>.fromJson(
      json,
      (dataJson) => TopicModel.fromJson(dataJson as Map<String, dynamic>),
    );
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '详情加载失败' : result.message);
    }

    final topic = result.data;
    if (topic == null || topic.tid.isEmpty) {
      throw Exception('动态详情为空');
    }
    return topic;
  }

  /// 拉取动态列表；
  Future<TopicPageResult> getTopicList({
    required int page,
    Map<String, dynamic>? customParameters,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'showpraises': '1',
      'showcomments': '1',
    };

    if (customParameters != null) {
      queryParameters.addAll(customParameters);
    }
    
    final response = await HttpClient.instance.dio.get<Map<String, dynamic>>(
      '/api/topic/getlist',
      queryParameters: queryParameters,
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
