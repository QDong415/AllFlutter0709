import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:all_flutter0709/core/network/page_data.dart';
import 'package:all_flutter0709/features/conversation/data/models/remind_model.dart';

/// 动态提醒列表分页结果。
class RemindPageResult {
  const RemindPageResult({required this.items, required this.hasMore});

  final List<RemindModel> items;
  final bool hasMore;
}

/// 拉取赞、评论、@我（Android `topic/remindlist`）。
class RemindRepository {
  const RemindRepository();

  /// [remindType]：1 评论，2 赞，3 @我。
  Future<RemindPageResult> getRemindList({
    required int remindType,
    required int page,
  }) async {
    final response = await HttpClient.instance.get(
      '/api/topic/remindlist',
      queryParameters: <String, dynamic>{
        'remindtype': remindType,
        'page': page,
      },
    );

    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }

    final result = ApiResponse<PageData<RemindModel>>.fromJson(
      json,
      (pageJson) => PageData<RemindModel>.fromJson(
        pageJson as Map<String, dynamic>,
        (itemJson) => RemindModel.fromJson(itemJson as Map<String, dynamic>),
      ),
    );
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '提醒加载失败' : result.message);
    }

    final pageData = result.data;
    final items = pageData?.items ?? const <RemindModel>[];
    final hasMore = (pageData?.totalPage ?? 0) > page;
    return RemindPageResult(items: items, hasMore: hasMore);
  }
}
