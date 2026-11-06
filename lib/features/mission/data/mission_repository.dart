import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';
import 'package:all_flutter0709/features/mission/data/mission_sign_open_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  return const MissionRepository();
});

/// 连续签到接口。
class MissionRepository {
  const MissionRepository();

  /// 进入主界面时拉取签到状态（`POST /api/mission/open`）。
  Future<MissionSignOpenModel> fetchSignOpen() async {
    final response = await HttpClient.instance.post('/api/mission/open');
    final json = response.data;
    if (json is! Map<String, dynamic>) {
      throw Exception('服务器返回为空');
    }
    final result = ApiResponse<Map<String, dynamic>>.fromJson(json, (dataJson) {
      if (dataJson is Map<String, dynamic>) {
        return dataJson;
      }
      if (dataJson is Map) {
        return Map<String, dynamic>.from(dataJson);
      }
      return <String, dynamic>{};
    });
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '加载签到失败' : result.message);
    }
    return MissionSignOpenModel.fromJson(result.data ?? <String, dynamic>{});
  }

  /// 提交签到（`POST /api/mission/sign`）。
  Future<void> submitSign() async {
    final response = await HttpClient.instance.post('/api/mission/sign');
    final json = response.data;
    if (json is! Map<String, dynamic>) {
      throw Exception('服务器返回为空');
    }
    final result = ApiResponse<Object?>.fromJson(json);
    if (!result.success) {
      throw Exception(result.message.isEmpty ? '签到失败' : result.message);
    }
  }
}
