import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:all_flutter0709/features/comment/data/models/comment_model.dart';
import 'package:dio/dio.dart';

enum CommentTargetType {
  topic('1'),
  video('2');

  const CommentTargetType(this.apiValue);

  final String apiValue;
}

class CommentRepository {
  const CommentRepository();

  Future<CommentPageResult> getCommentList({
    required String targetId,
    required CommentTargetType type,
    required int page,
  }) async {
    final response = await HttpClient.instance.dio.get<Map<String, dynamic>>(
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

  Future<CommentPageResult> getChildCommentList({
    required String parentCid,
    required String startCid,
  }) async {
    final response = await HttpClient.instance.dio.get<Map<String, dynamic>>(
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

    final response = await HttpClient.instance.dio.post<Map<String, dynamic>>(
      '/api/comment/submit',
      data: payload,
      options: Options(contentType: Headers.formUrlEncodedContentType),
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

  Future<void> likeComment({
    required String cid,
    required bool isLiked,
    required int likeCount,
  }) async {
    final response = await HttpClient.instance.dio.post<Map<String, dynamic>>(
      '/api/comment/like',
      data: <String, dynamic>{
        'dataid': cid,
        'cid': cid,
        'api': 'comment/like',
        'like': isLiked ? '1' : '0',
        'likecount': '$likeCount',
        'type': '2',
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
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
