import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:all_flutter0709/core/network/page_data.dart';
import 'package:all_flutter0709/features/ai/data/models/ai_character_model.dart';

/// AI 角色筛选类型。
enum AiCharacterFilter {
  female(label: '女生'),
  male(label: '男生');

  const AiCharacterFilter({required this.label});

  final String label;
}

/// AI 角色列表分页结果。
class AiCharacterPageResult {
  const AiCharacterPageResult({
    required this.characterModelList,
    required this.hasMore,
  });

  final List<AiCharacterModel> characterModelList;
  final bool hasMore;
}

/// AI 角色发现相关网络请求。
class AiCharacterRepository {
  const AiCharacterRepository();

  /// 按筛选条件拉取 AI 角色列表。
  Future<AiCharacterPageResult> getCharacterList({
    required int page,
    required AiCharacterFilter filter,
    String keyword = '',
    int pageSize = 20,
  }) async {
    final response = await HttpClient.instance.get(
      '/api/ai/getlist',
      queryParameters: <String, dynamic>{
        'page': page,
        'pagesize': pageSize,
        if (filter == AiCharacterFilter.female) 'gender': 2,
        if (filter == AiCharacterFilter.male) 'gender': 1,
        'sort': 'recommend',
        if (keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
      },
    );

    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }

    final result = ApiResponse<PageData<AiCharacterModel>>.fromJson(
      json,
      (pageJson) => PageData<AiCharacterModel>.fromJson(
        pageJson as Map<String, dynamic>,
        (itemJson) =>
            AiCharacterModel.fromJson(itemJson as Map<String, dynamic>),
      ),
    );
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '请求失败' : result.message);
    }

    final pageData = result.data;
    final characterModelList = pageData?.items ?? const <AiCharacterModel>[];
    return AiCharacterPageResult(
      characterModelList: characterModelList,
      hasMore: (pageData?.totalPage ?? 0) > page,
    );
  }
}
