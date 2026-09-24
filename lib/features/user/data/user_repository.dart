import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:all_flutter0709/core/network/page_data.dart';
import 'package:all_flutter0709/features/user/data/models/user_base_model.dart';
import 'package:all_flutter0709/features/user/data/models/user_profile_model.dart';

/// 用户主页相关网络请求。
class UserRepository {
  const UserRepository();

  /// 拉取用户资料；有 [toUserId] 时按 id，否则按 [toName]（动态 @提及）。
  Future<UserProfileModel> getUserProfile({
    String toUserId = '',
    String toName = '',
  }) async {
    final trimmedId = toUserId.trim();
    final queryParameters = <String, dynamic>{};
    if (trimmedId.isNotEmpty && trimmedId != '0') {
      queryParameters['to_userid'] = trimmedId;
    } else {
      queryParameters['to_name'] = toName.trim();
    }

    final response = await HttpClient.instance.get(
      '/api/user/profile',
      queryParameters: queryParameters,
    );

    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }

    final result = ApiResponse<UserProfileModel>.fromJson(
      json,
      (dataJson) => UserProfileModel.fromJson(dataJson as Map<String, dynamic>),
    );
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '资料加载失败' : result.message);
    }

    final profile = result.data;
    if (profile == null || profile.userId.isEmpty) {
      throw Exception('用户资料为空');
    }
    return profile;
  }

  /// 关注 / 取消关注，返回最新关系状态（0/1/2/3）。
  Future<int> followUser({required String toUserId}) async {
    final response = await HttpClient.instance.post(
      '/api/follow/follow',
      data: <String, dynamic>{'to_userid': toUserId},
    );

    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }

    final result = ApiResponse<int>.fromJson(json, (dataJson) {
      if (dataJson is int) return dataJson;
      if (dataJson is num) return dataJson.toInt();
      return int.tryParse(dataJson?.toString() ?? '') ?? 0;
    });
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '关注失败' : result.message);
    }

    final followStatus = result.data ?? 0;
    if (followStatus == 1 || followStatus == 3) {
      // 对齐 Android：关注成功后通知服务端 didfollow（失败忽略）。
      try {
        await HttpClient.instance.post(
          '/api/follow/didfollow',
          data: <String, dynamic>{'to_userid': toUserId},
        );
      } catch (_) {}
    }

    return followStatus;
  }

  /// 提交意见或举报（Android `version/opinion_send`）。
  Future<void> submitOpinion({
    required String content,
    String toUserId = '',
  }) async {
    final response = await HttpClient.instance.post(
      '/api/version/opinion_send',
      data: <String, dynamic>{'to_userid': toUserId, 'content': content},
    );

    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }

    final result = ApiResponse<void>.fromJson(json);
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '提交失败' : result.message);
    }
  }

  /// 拉取我关注的好友列表（Android `follow/folowlist`）。
  Future<UserBasePageResult> getFollowList({
    required String toUserId,
    required int page,
    String keyword = '',
  }) async {
    final response = await HttpClient.instance.get(
      '/api/follow/folowlist',
      queryParameters: <String, dynamic>{
        'to_userid': toUserId,
        'page': page,
        'keyword': keyword,
      },
    );

    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }

    final result = ApiResponse<PageData<UserBaseModel>>.fromJson(
      json,
      (pageJson) => PageData<UserBaseModel>.fromJson(
        pageJson as Map<String, dynamic>,
        (itemJson) => UserBaseModel.fromJson(itemJson as Map<String, dynamic>),
      ),
    );
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '好友列表加载失败' : result.message);
    }

    final pageData = result.data;
    final items = pageData?.items ?? const <UserBaseModel>[];
    final hasMore = (pageData?.totalPage ?? 0) > page;
    return UserBasePageResult(items: items, hasMore: hasMore);
  }

  /// 拉取我的粉丝列表（Android `follow/fanslist`）。
  Future<UserBasePageResult> getFansList({
    required String toUserId,
    required int page,
  }) async {
    final response = await HttpClient.instance.get(
      '/api/follow/fanslist',
      queryParameters: <String, dynamic>{
        'to_userid': toUserId,
        'page': page,
      },
    );

    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }

    final result = ApiResponse<PageData<UserBaseModel>>.fromJson(
      json,
      (pageJson) => PageData<UserBaseModel>.fromJson(
        pageJson as Map<String, dynamic>,
        (itemJson) => UserBaseModel.fromJson(itemJson as Map<String, dynamic>),
      ),
    );
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '粉丝列表加载失败' : result.message);
    }

    final pageData = result.data;
    final items = pageData?.items ?? const <UserBaseModel>[];
    final hasMore = (pageData?.totalPage ?? 0) > page;
    return UserBasePageResult(items: items, hasMore: hasMore);
  }

  /// 拉取用户列表（Android `user/getlist`，匹配 Tab 传 vip=1）。
  Future<UserBasePageResult> getUserList({
    required int page,
    int gender = 0,
    int vip = 0,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      if (gender != 0) 'gender': gender,
      if (vip != 0) 'vip': vip,
    };

    final response = await HttpClient.instance.get(
      '/api/user/getlist',
      queryParameters: queryParameters,
    );

    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }

    final result = ApiResponse<PageData<UserBaseModel>>.fromJson(
      json,
      (pageJson) => PageData<UserBaseModel>.fromJson(
        pageJson as Map<String, dynamic>,
        (itemJson) => UserBaseModel.fromJson(itemJson as Map<String, dynamic>),
      ),
    );
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '用户列表加载失败' : result.message);
    }

    final pageData = result.data;
    final items = pageData?.items ?? const <UserBaseModel>[];
    final hasMore = (pageData?.totalPage ?? 0) > page;
    return UserBasePageResult(items: items, hasMore: hasMore);
  }
}

/// 关注列表分页结果。
class UserBasePageResult {
  const UserBasePageResult({required this.items, required this.hasMore});

  final List<UserBaseModel> items;
  final bool hasMore;
}
