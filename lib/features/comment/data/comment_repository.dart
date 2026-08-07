import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:all_flutter0709/features/comment/data/models/comment_model.dart';

/// 评论目标类型（动态 / 视频）。
enum CommentTargetType {
  topic('1'),
  video('2');

  const CommentTargetType(this.apiValue);

  final String apiValue;
}

/// 评论相关网络请求。
class CommentRepository {
  const CommentRepository();

  /// 拉取一级评论列表。
  Future<CommentPageResult> getCommentList({
    required String targetId,
    required CommentTargetType type,
    required int page,
  }) async {
    final response = await HttpClient.instance.get(
      '/api/comment/getlist',
      queryParameters: <String, dynamic>{
        'tid': targetId,
        'type': type.apiValue,
        'page': page,
      },
    );

    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }

    final result = ApiResponse<CommentPageResult>.fromJson(
      json,
      (dataJson) => CommentPageResult.fromJson(dataJson, page: page),
    );
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '评论加载失败' : result.message);
    }

    return result.data ??
        const CommentPageResult(
          items: <CommentModel>[],
          hasMore: false,
          total: 0,
        );
  }

  /// 拉取子评论列表。
  Future<CommentPageResult> getChildCommentList({
    required String parentCid,
    required String startCid,
  }) async {
    final response = await HttpClient.instance.get(
      '/api/comment/childlist',
      queryParameters: <String, dynamic>{
        'pcid': parentCid,
        'startcid': startCid,
      },
    );

    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }

    final result = ApiResponse<CommentPageResult>.fromJson(
      json,
      (dataJson) => CommentPageResult.fromJson(dataJson, page: 1),
    );
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '回复加载失败' : result.message);
    }

    return result.data ??
        const CommentPageResult(
          items: <CommentModel>[],
          hasMore: false,
          total: 0,
        );
  }

  /// 提交评论或回复。
  Future<CommentSubmitResult> submitComment({
    required String targetId,
    required CommentTargetType type,
    required String content,
    required String tempId,
    String? parentCid,
    String? toUserId,
    String? toUserName,
  }) async {
    final payload = <String, dynamic>{
      'tid': targetId,
      'type': type.apiValue,
      'content': content,
      'tempid': tempId,
      if (parentCid != null && parentCid.isNotEmpty) 'pcid': parentCid,
      if (toUserId != null && toUserId.isNotEmpty) 'to_userid': toUserId,
      if (toUserName != null && toUserName.isNotEmpty) 'to_name': toUserName,
    };

    final response = await HttpClient.instance.post(
      '/api/comment/submit',
      data: payload,
    );

    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }

    final result = ApiResponse<CommentSubmitResult>.fromJson(
      json,
      (dataJson) => CommentSubmitResult.fromJson(dataJson),
    );
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '评论发送失败' : result.message);
    }

    return result.data ?? CommentSubmitResult(cid: '', tempId: tempId);
  }

  /// 点赞 / 取消点赞评论。
  Future<void> likeComment({
    required String cid,
    required bool isLiked,
    required int likeCount,
  }) async {
    final response = await HttpClient.instance.post(
      '/api/comment/like',
      data: <String, dynamic>{
        'dataid': cid,
        'cid': cid,
        'api': 'comment/like',
        'like': isLiked ? '1' : '0',
        'likecount': '$likeCount',
        'type': '2',
      },
    );

    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }

    final result = ApiResponse<void>.fromJson(json);
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '评论点赞失败' : result.message);
    }
  }
}
