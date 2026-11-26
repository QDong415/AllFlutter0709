import 'package:all_flutter0709/core/network/api_response.dart';
import 'package:all_flutter0709/core/network/http_client.dart';

/// 注册前按当前网络 IP 向服务端要预填邀请码。
class InviteRepository {
  const InviteRepository();

  /// 窗口内该 IP 只有一个邀请码时返回它，否则返回空字符串。失败也返回空。
  Future<String> matchInviteCode() async {
    try {
      final response = await HttpClient.instance.post('/api/invite/match');
      final json = response.data;
      if (json == null) {
        return '';
      }
      final result = ApiResponse<String>.fromJson(json, (dataJson) {
        if (dataJson is Map) {
          return dataJson['invitecode']?.toString().trim() ?? '';
        }
        return '';
      });
      if (!result.success) {
        return '';
      }
      return result.data ?? '';
    } catch (_) {
      return '';
    }
  }
}
