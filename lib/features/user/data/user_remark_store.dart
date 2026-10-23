import 'dart:convert';

import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/core/account/account_repository.dart';
import 'package:all_flutter0709/features/user/data/user_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 当前用户给他人设置的备注。
///
/// 只用于聊天里的显示名。动态、评论、个人主页标题仍用对方昵称。
class UserRemarkStore extends ChangeNotifier {
  UserRemarkStore(this._preferences);

  static const _maxLength = 16;

  final SharedPreferences _preferences;
  final UserRepository _repository = const UserRepository();

  String _myUserId = '';
  int _requestTicket = 0;
  final Set<String> _syncingUserIdSet = <String>{};
  final Map<String, String> _remarkMap = <String, String>{};

  /// 备注最长字数，与服务端 `user_remark.remark` 一致。
  int get maxLength => _maxLength;

  /// 登录或切换账号时，加载该账号保存在本机的备注。空 id 表示已退出。
  void switchToLoggedInUser(String myUserId) {
    final nextUserId = myUserId.trim();
    if (nextUserId == _myUserId) {
      return;
    }
    _myUserId = nextUserId;
    _requestTicket++;
    _remarkMap
      ..clear()
      ..addAll(_read(nextUserId));
    notifyListeners();
  }

  /// 聊天里展示的名字：有备注用备注，否则用昵称。
  String displayName({required String userId, required String nickname}) {
    final remark = remarkOf(userId);
    if (remark.isNotEmpty) {
      return remark;
    }
    return nickname.trim();
  }

  /// 当前用户给 [userId] 写的备注；没有则返回空字符串。
  String remarkOf(String userId) {
    return _remarkMap[userId.trim()] ?? '';
  }

  /// 登录成功后从服务端拉全量备注并覆盖当前账号的本地缓存。
  Future<void> syncFromServer() async {
    final myUserId = _myUserId;
    if (myUserId.isEmpty || _syncingUserIdSet.contains(myUserId)) {
      return;
    }
    _syncingUserIdSet.add(myUserId);
    final ticket = _requestTicket;
    try {
      final remarkMap = await _repository.fetchRemarkMap();
      if (ticket != _requestTicket || myUserId != _myUserId) {
        return;
      }
      _remarkMap
        ..clear()
        ..addAll(remarkMap);
      _persist(myUserId);
      notifyListeners();
    } catch (error) {
      debugPrint('备注列表刷新失败: $error');
    } finally {
      _syncingUserIdSet.remove(myUserId);
    }
  }

  /// 写入一条备注。空字符串表示清除。
  ///
  /// [localEdit] 为 true 时丢弃正在进行的全量刷新，避免旧列表把刚保存的备注盖掉。
  void put({
    required String toUserId,
    required String remark,
    bool localEdit = false,
  }) {
    final targetUserId = toUserId.trim();
    if (_myUserId.isEmpty || targetUserId.isEmpty) {
      return;
    }
    if (localEdit) {
      _requestTicket++;
    }
    final text = remark.trim();
    if (text.isEmpty) {
      if (!_remarkMap.containsKey(targetUserId)) {
        return;
      }
      _remarkMap.remove(targetUserId);
    } else {
      if (_remarkMap[targetUserId] == text) {
        return;
      }
      _remarkMap[targetUserId] = text;
    }
    _persist(_myUserId);
    notifyListeners();
  }

  Map<String, String> _read(String userId) {
    if (userId.isEmpty) {
      return <String, String>{};
    }
    final raw = _preferences.getString(_key(userId));
    if (raw == null || raw.isEmpty) {
      return <String, String>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, String>{};
      }
      final remarkMap = <String, String>{};
      decoded.forEach((key, value) {
        final targetUserId = key.toString().trim();
        final remark = value?.toString().trim() ?? '';
        if (targetUserId.isEmpty || remark.isEmpty) {
          return;
        }
        remarkMap[targetUserId] = remark;
      });
      return remarkMap;
    } catch (_) {
      return <String, String>{};
    }
  }

  void _persist(String userId) {
    if (userId.isEmpty) {
      return;
    }
    _preferences.setString(_key(userId), jsonEncode(_remarkMap));
  }

  String _key(String userId) => 'user-remark-map-$userId';
}

final userRemarkStoreProvider = Provider<UserRemarkStore>((ref) {
  final store = UserRemarkStore(ref.watch(sharedPreferencesProvider));
  store.switchToLoggedInUser(ref.read(accountProvider)?.userId ?? '');
  ref.listen(accountProvider, (previous, next) {
    store.switchToLoggedInUser(next?.userId ?? '');
  });
  ref.onDispose(store.dispose);
  return store;
});
