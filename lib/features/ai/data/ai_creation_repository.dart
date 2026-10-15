import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:all_flutter0709/features/ai/data/models/ai_creation_model.dart';

/// 用户自定义 AI 的创建与同步生图请求。
class AiCreationRepository {
  const AiCreationRepository();

  static const _moderationTimeout = Duration(seconds: 45);
  static const _generationTimeout = Duration(seconds: 180);

  /// 创建私有草稿。
  Future<AiCreationModel> create({
    required String name,
    required int gender,
    required String personality,
    required String outfit,
    required String career,
    required String personaInput,
  }) {
    return _post(
      '/api/ai/creationcreate',
      data: <String, dynamic>{
        'name': name,
        'gender': gender,
        'personality': personality,
        'outfit': outfit,
        'career': career,
        'persona_input': personaInput,
      },
      timeout: _moderationTimeout,
    );
  }

  /// 同步生成头像。
  Future<AiCreationModel> generateAvatar(int creationId) {
    return _post(
      '/api/ai/creationavatar',
      data: <String, dynamic>{'creation_id': creationId},
      timeout: _generationTimeout,
    );
  }

  /// 同步生成全身图。
  Future<AiCreationModel> generateFullBody(int creationId) {
    return _post(
      '/api/ai/creationfullbody',
      data: <String, dynamic>{'creation_id': creationId},
      timeout: _generationTimeout,
    );
  }

  /// 确认候选图片并发布 AI。
  Future<AiCreationModel> confirm(int creationId) {
    return _post(
      '/api/ai/creationconfirm',
      data: <String, dynamic>{'creation_id': creationId},
    );
  }

  Future<AiCreationModel> _post(
    String path, {
    required Map<String, dynamic> data,
    Duration? timeout,
  }) async {
    final response = await HttpClient.instance.post(
      path,
      data: data,
      sendTimeout: timeout,
      receiveTimeout: timeout,
    );
    final json = response.data;
    if (json == null) {
      throw Exception('服务器返回为空');
    }
    final result = ApiResponse<AiCreationModel>.fromJson(
      json,
      (value) => AiCreationModel.fromJson(value as Map<String, dynamic>),
    );
    if (!result.success || result.data == null) {
      throw Exception(result.message.isEmpty ? '请求失败' : result.message);
    }
    return result.data!;
  }
}
