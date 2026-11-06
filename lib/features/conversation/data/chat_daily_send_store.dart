import 'package:all_flutter0709/core/account/account_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final chatDailySendStoreProvider = Provider<ChatDailySendStore>((ref) {
  return ChatDailySendStore(ref.watch(sharedPreferencesProvider));
});

/// 非会员当日已成功发出的文本/语音条数。
///
/// 单独存在 SharedPreferences，删除本地聊天记录不会把额度清掉。
/// 按北京时间自然日分 key，过 0 点换一天。
class ChatDailySendStore {
  ChatDailySendStore(this._preferences);

  final SharedPreferences _preferences;

  int todaySendCount(String userId) {
    if (userId.isEmpty) {
      return 0;
    }
    return _preferences.getInt(_storageKey(userId)) ?? 0;
  }

  Future<void> recordSend(String userId) async {
    if (userId.isEmpty) {
      return;
    }
    final key = _storageKey(userId);
    final next = (_preferences.getInt(key) ?? 0) + 1;
    await _preferences.setInt(key, next);
  }

  String _storageKey(String userId) {
    return 'chat_sent_count_${userId}_${_chinaDayKey()}';
  }

  /// 北京时间的日期，设备时区不同也不会把「今天」算错。
  static String _chinaDayKey() {
    final china = DateTime.now().toUtc().add(const Duration(hours: 8));
    final month = china.month.toString().padLeft(2, '0');
    final day = china.day.toString().padLeft(2, '0');
    return '${china.year}$month$day';
  }
}
