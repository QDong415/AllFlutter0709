import 'package:all_flutter0709/core/account/account_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 动态互动提醒类型，对齐 Android `ChatManager.REMIND_SUBTYPE_*`。
enum RemindKind {
  praise,
  comment,
  fans,
  at,
}

/// 会话列表顶部四条提醒的本地未读。
///
/// 对齐 Android：推送 payload 的 dataid 记在本地，打开对应列表后全部已读。
class RemindUnreadStore extends ChangeNotifier {
  RemindUnreadStore(this._preferences);

  final SharedPreferences _preferences;

  /// 记录一条未读提醒。
  void insert({
    required String userId,
    required RemindKind kind,
    required String dataId,
  }) {
    final id = dataId.trim();
    if (userId.isEmpty || id.isEmpty) {
      return;
    }
    final ids = _read(userId, kind);
    if (ids.contains(id)) {
      return;
    }
    ids.add(id);
    _write(userId, kind, ids);
    notifyListeners();
  }

  /// 打开对应列表时清空该类未读。
  void readAll({required String userId, required RemindKind kind}) {
    if (userId.isEmpty) {
      return;
    }
    if (_read(userId, kind).isEmpty) {
      return;
    }
    _write(userId, kind, <String>{});
    notifyListeners();
  }

  /// 某一类未读数。
  int countOf({required String userId, required RemindKind kind}) {
    if (userId.isEmpty) {
      return 0;
    }
    return _read(userId, kind).length;
  }

  /// 四类未读合计，用于消息 Tab 角标。
  int totalOf(String userId) {
    if (userId.isEmpty) {
      return 0;
    }
    var total = 0;
    for (final kind in RemindKind.values) {
      total += countOf(userId: userId, kind: kind);
    }
    return total;
  }

  Set<String> _read(String userId, RemindKind kind) {
    return _preferences.getStringList(_key(userId, kind))?.toSet() ??
        <String>{};
  }

  void _write(String userId, RemindKind kind, Set<String> ids) {
    _preferences.setStringList(_key(userId, kind), ids.toList());
  }

  String _key(String userId, RemindKind kind) {
    final prefix = switch (kind) {
      RemindKind.praise => 'UNREAD_PRAISE_REMIND_',
      RemindKind.comment => 'UNREAD_COMMENT_REMIND_',
      RemindKind.fans => 'UNREAD_FANS_REMIND_',
      RemindKind.at => 'UNREAD_AT_REMIND_',
    };
    return '$prefix$userId';
  }
}

final remindUnreadStoreProvider = Provider<RemindUnreadStore>((ref) {
  final store = RemindUnreadStore(ref.watch(sharedPreferencesProvider));
  ref.onDispose(store.dispose);
  return store;
});
