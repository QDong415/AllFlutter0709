import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:all_flutter0709/app/router/app_router.dart';
import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/core/account/account.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/core/account/account_repository.dart';
import 'package:all_flutter0709/core/push/getui_push_config.dart';
import 'package:all_flutter0709/features/conversation/presentation/conversation_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getuiflut/getuiflut.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

/// 个推推送服务 Provider。
///
/// 职责概览：
/// 1. 启动原生个推 SDK，收 ClientId / 通知 / 透传
/// 2. 把业务 payload（如 needpull）转成「拉消息」
/// 3. 处理通知点击跳转（含冷启动、未登录先记 pending）
///
/// 关于会话刷新为什么有两个调用入口（方法不同、实现相同）：
/// - [ConversationController.onLoginStateChanged]：运行期登录/退出（listen）
/// - [ConversationController.checkedLoginStateAfterInitedApp]：启动后补当前登录态
/// 二者最终都走到 ConversationController 内部的同一套刷新逻辑，只是触发时机不同。
final getuiPushServiceProvider = Provider<GetuiPushService>((ref) {
  final service = GetuiPushService(ref);

  // 【入口 A】账号 userId 变化时（登录成功 / 退出登录）
  // Riverpod 的 listen 只在「变化后」触发，不会在订阅当下立刻带上当前 account。
  ref.listen<AccountModel?>(accountProvider, (previous, next) {
    if (previous?.userId == next?.userId) {
      return;
    }
    // 通知会话层：清空或拉取本地会话 + message/pull
    unawaited(
      ref.read(conversationControllerProvider).onLoginStateChanged(next),
    );
    if (next != null) {
      // 登录后：把本地缓存的 CID 再上报一次；消费「点通知但当时未登录」留下的跳转
      unawaited(service.syncCachedClientId());
      service.markLoginRestored();
      unawaited(service.flushPendingNavigation());
    }
  });
  ref.onDispose(service.dispose);
  return service;
});

/// 个推 Flutter 封装的业务侧门面（日志、导航、与会话模块联动）。
class GetuiPushService extends ChangeNotifier {
  GetuiPushService(this._ref);

  static const _clientIdStorageKey = 'getui-client-id';
  static const _maxEventLogs = 30;

  final Ref _ref;
  final Getuiflut _plugin = Getuiflut();
  final Logger _logger = Logger();

  bool _initialized = false;
  String _currentClientId = '';

  /// 通知点击时若尚未登录，先记下目标会话，登录后再跳。
  String _pendingConversationId = '';

  /// 没有具体会话 id 时，登录后只打开会话列表 Tab。
  bool _pendingOpenConversationList = false;
  String _latestEventSummary = '尚未收到推送事件';
  Map<String, dynamic>? _lastBusinessPayload;
  Map<String, dynamic>? _lastRawEvent;
  final List<String> _eventLogs = <String>[];

  String get currentClientId => _currentClientId;
  String get pendingConversationId => _pendingConversationId;
  String get latestEventSummary => _latestEventSummary;
  List<String> get eventLogs => List<String>.unmodifiable(_eventLogs);
  Map<String, dynamic>? get lastBusinessPayload => _lastBusinessPayload == null
      ? null
      : Map<String, dynamic>.from(_lastBusinessPayload!);
  Map<String, dynamic>? get lastRawEvent =>
      _lastRawEvent == null ? null : Map<String, dynamic>.from(_lastRawEvent!);

  /// App 启动时调用一次：注册回调、拉起 SDK、补齐登录态与冷启动通知。
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _appendLog('开始初始化个推');

    // 原生 SDK 事件 → 本类私有方法
    _plugin.addEventHandler(
      onReceiveClientId: _onReceiveClientId,
      onNotificationMessageArrived: _onNotificationMessageArrived,
      onNotificationMessageClicked: _onNotificationMessageClicked,
      onTransmitUserMessageReceive: _onTransmitUserMessageReceive,
      onReceiveOnlineState: _onReceiveOnlineState,
      onRegisterDeviceToken: _onRegisterDeviceToken,
      onReceivePayload: _onReceivePayload,
      onReceiveNotificationResponse: _onReceiveNotificationResponse,
      onAppLinkPayload: _onAppLinkPayload,
      onPushModeResult: _noopMap,
      onSetTagResult: _noopMap,
      onAliasResult: _noopMap,
      onQueryTagResult: _noopMap,
      onWillPresentNotification: _noopMap,
      onOpenSettingsForNotification: _noopMap,
      onGrantAuthorization: _onGrantAuthorization,
      onLiveActivityResult: _noopMap,
      onRegisterPushToStartTokenResult: _noopMap,
    );

    if (Platform.isAndroid) {
      _plugin.initGetuiSdk;
      _plugin.onActivityCreate();
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
      _plugin.turnOnPush();
    } else if (Platform.isIOS) {
      _plugin.startSdk(
        appId: GetuiPushConfig.appId,
        appKey: GetuiPushConfig.appKey,
        appSecret: GetuiPushConfig.appSecret,
      );
    }

    // 【入口 B】启动时用「当前账号」补一次会话同步。
    // 冷启动常见顺序：SharedPreferences 已恢复登录 → 才创建本 Provider / 才 listen。
    // 此时 listen 不会回调，若不在这里调，已登录用户要等下次登录变化才拉会话。
    unawaited(
      _ref
          .read(conversationControllerProvider)
          .checkedLoginStateAfterInitedApp(_ref.read(accountProvider)),
    );
    // 杀进程后点通知拉起：从原生侧读启动参数并尝试跳转
    unawaited(_readLaunchNotification());
    // CID：本地缓存先用上，再向 SDK 主动问一次
    unawaited(syncCachedClientId());
    unawaited(refreshClientIdFromSdk());
    _appendLog('个推初始化完成');
  }

  void markLoginRestored() {
    _latestEventSummary = '登录状态恢复';
    notifyListeners();
  }

  // --- 个推 SDK 回调（命名与插件一致）---

  /// 拿到 CID：本地缓存 + 上报业务后端（modifyarray）
  Future<dynamic> _onReceiveClientId(String clientId) async {
    _appendLog('onReceiveClientId: $clientId');
    final preferences = _ref.read(sharedPreferencesProvider);
    _currentClientId = clientId;
    _latestEventSummary = '收到个推 ClientId';
    notifyListeners();
    await preferences.setString(_clientIdStorageKey, clientId);
    await _ref.read(conversationControllerProvider).syncPushClientId(clientId);
  }

  /// 通知送达（未点击）：只处理业务（如 needpull 拉消息），不跳转
  Future<dynamic> _onNotificationMessageArrived(
    Map<String, dynamic> message,
  ) async {
    _captureRawEvent('onNotificationMessageArrived', message);
    await _handlePayloadCandidate(message, fromClick: false);
  }

  /// 用户点击通知（多为 Android）：拉消息 + 尝试跳转
  Future<dynamic> _onNotificationMessageClicked(
    Map<String, dynamic> message,
  ) async {
    _captureRawEvent('onNotificationMessageClicked', message);
    await _handlePayloadCandidate(message, fromClick: true);
    await _navigateFromPushData(message, fromClick: true);
  }

  /// iOS 透传等：拉消息；有 taskId/messageId 时回执
  Future<dynamic> _onReceivePayload(Map<String, dynamic> message) async {
    _captureRawEvent('onReceivePayload', message);
    await _handlePayloadCandidate(message, fromClick: false);
    _sendFeedbackIfPossible(message);
  }

  /// iOS 用户点了通知栏：等同点击跳转
  Future<dynamic> _onReceiveNotificationResponse(
    Map<String, dynamic> message,
  ) async {
    _captureRawEvent('onReceiveNotificationResponse', message);
    await _handlePayloadCandidate(message, fromClick: true);
    await _navigateFromPushData(message, fromClick: true);
  }

  Future<dynamic> _onAppLinkPayload(String payload) async {
    _appendLog('onAppLinkPayload: $payload');
    final map = _tryParsePayloadString(payload);
    if (map != null) {
      await _handleBusinessPayload(map);
      await _navigateFromPushData(map, fromClick: true);
    }
  }

  Future<dynamic> _onTransmitUserMessageReceive(
    Map<String, dynamic> message,
  ) async {
    _captureRawEvent('onTransmitUserMessageReceive', message);
    await _handlePayloadCandidate(message, fromClick: false);
  }

  Future<dynamic> _onReceiveOnlineState(String online) async {
    _appendLog('onReceiveOnlineState: $online');
    _latestEventSummary = '个推在线状态: $online';
    notifyListeners();
  }

  Future<dynamic> _onRegisterDeviceToken(String token) async {
    _appendLog('onRegisterDeviceToken: $token');
    _latestEventSummary = '收到 DeviceToken';
    notifyListeners();
  }

  Future<dynamic> _onGrantAuthorization(String granted) async {
    _appendLog('onGrantAuthorization: $granted');
    _latestEventSummary = '通知权限: $granted';
    notifyListeners();
  }

  /// 冷启动：进程被通知拉起时，从原生读启动参数再导航（需稍等 router）
  Future<void> _readLaunchNotification() async {
    try {
      final launchData = await _plugin.getLaunchNotification;
      if (launchData.isEmpty) {
        _appendLog('冷启动通知为空');
        return;
      }
      final map = launchData.cast<String, dynamic>();
      _captureRawEvent('getLaunchNotification', map);
      _latestEventSummary = '冷启动读取到通知';
      notifyListeners();
      await _handlePayloadCandidate(map, fromClick: true);
      // 冷启动时 router 可能尚未 ready，稍后再跳。
      await Future<void>.delayed(const Duration(milliseconds: 450));
      await _navigateFromPushData(map, fromClick: true);
    } catch (error) {
      _appendLog('冷启动通知读取失败: $error');
    }

    try {
      final localLaunch = await _plugin.getLaunchLocalNotification;
      if (localLaunch.isNotEmpty) {
        final map = localLaunch.cast<String, dynamic>();
        _captureRawEvent('getLaunchLocalNotification', map);
        await _handlePayloadCandidate(map, fromClick: true);
        await Future<void>.delayed(const Duration(milliseconds: 450));
        await _navigateFromPushData(map, fromClick: true);
      }
    } catch (_) {
      // 本地通知启动参数不是必需能力
    }
  }

  /// 从 SDK 原始 map 里抠出业务 JSON，再交给 [_handleBusinessPayload]
  Future<void> _handlePayloadCandidate(
    Map<String, dynamic> payload, {
    required bool fromClick,
  }) async {
    final decodedPayload = _extractBusinessPayload(payload);
    if (decodedPayload == null) {
      _appendLog('未解析出业务 payload${fromClick ? '（点击）' : ''}');
      return;
    }
    _lastBusinessPayload = Map<String, dynamic>.from(decodedPayload);
    await _handleBusinessPayload(decodedPayload);
  }

  /// 对齐旧工程：needpull=1 或 type 为聊天相关 → message/pull
  Future<void> _handleBusinessPayload(Map<String, dynamic> payload) async {
    final needPull = payload['needpull']?.toString() == '1';
    final type = int.tryParse(payload['type']?.toString() ?? '');
    _latestEventSummary = '收到业务 payload: ${jsonEncode(payload)}';
    notifyListeners();
    _appendLog('业务 payload: ${jsonEncode(payload)}');

    if (needPull || type == 1 || type == 2) {
      await _ref.read(conversationControllerProvider).syncMessagesFromServer();
    }
  }

  Map<String, dynamic>? _extractBusinessPayload(Map<String, dynamic> payload) {
    final candidates = [
      payload['payload'],
      payload['payloadMsg'],
      payload['payloadMsgDic'],
      payload['content'],
      payload['body'],
      payload['n'],
      payload['p'],
    ];

    for (final candidate in candidates) {
      if (candidate is Map) {
        final map = candidate.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        if (_looksLikeBusinessPayload(map)) {
          return map;
        }
      }
      final decoded = _tryParsePayloadString(candidate?.toString() ?? '');
      if (decoded != null) {
        return decoded;
      }
    }

    if (_looksLikeBusinessPayload(payload)) {
      return payload;
    }
    return null;
  }

  bool _looksLikeBusinessPayload(Map<String, dynamic> payload) {
    return payload.containsKey('needpull') ||
        payload.containsKey('targetid') ||
        payload.containsKey('other_userid') ||
        payload.containsKey('chatId') ||
        payload.containsKey('type') ||
        payload.containsKey('dataid');
  }

  Map<String, dynamic>? _tryParsePayloadString(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// 把本地缓存的 CID 同步到内存，并在已登录时上报后端
  Future<void> syncCachedClientId() async {
    final preferences = _ref.read(sharedPreferencesProvider);
    final clientId = preferences.getString(_clientIdStorageKey) ?? '';
    if (clientId.isEmpty) {
      return;
    }
    _currentClientId = clientId;
    notifyListeners();
    await _ref.read(conversationControllerProvider).syncPushClientId(clientId);
  }

  /// 主动向 SDK 要一次 CID（联调面板「刷新 CID」也会走这里）
  Future<void> refreshClientIdFromSdk() async {
    try {
      final clientId = (await _plugin.getClientId).trim();
      if (clientId.isEmpty) {
        _appendLog('主动读取 ClientId 为空');
        return;
      }
      _currentClientId = clientId;
      _latestEventSummary = '主动读取到 ClientId';
      notifyListeners();
      final preferences = _ref.read(sharedPreferencesProvider);
      await preferences.setString(_clientIdStorageKey, clientId);
      await _ref.read(conversationControllerProvider).syncPushClientId(clientId);
      _appendLog('主动读取 ClientId: $clientId');
    } catch (error) {
      _appendLog('主动读取 ClientId 失败: $error');
    }
  }

  Future<void> copyClientIdToClipboard() async {
    final clientId = _currentClientId.trim();
    if (clientId.isEmpty) {
      await refreshClientIdFromSdk();
    }
    final value = _currentClientId.trim();
    if (value.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: value));
    _latestEventSummary = 'ClientId 已复制';
    notifyListeners();
  }

  /// 登录成功后：若之前点过通知留下了 pending，这里真正执行 go/push
  Future<void> flushPendingNavigation() async {
    if (_ref.read(accountProvider) == null) {
      return;
    }
    final location = consumePendingNavigationLocation();
    if (location == null) {
      return;
    }
    _appendLog('登录后消费待跳转: $location');
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final router = _ref.read(appRouterProvider);
    if (location == AppRoutes.conversation) {
      router.go(location);
      return;
    }
    router.go(AppRoutes.conversation);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    router.push(location);
  }

  /// 仅 fromClick=true 时导航。
  /// 无 targetid 时：先 pull，再跳最近未读；再没有就进会话列表。
  Future<void> _navigateFromPushData(
    Map<String, dynamic> payload, {
    required bool fromClick,
  }) async {
    if (!fromClick) {
      return;
    }

    final businessPayload =
        _extractBusinessPayload(payload) ?? _lastBusinessPayload ?? payload;
    var targetId = _readTargetId(businessPayload);

    // 旧工程很多聊天推送只有 needpull=1，没有 targetid。
    // 先同步消息，再尽量落到最近未读会话；拿不到就进会话列表。
    final needPull = businessPayload['needpull']?.toString() == '1';
    if (targetId.isEmpty && needPull) {
      await _ref.read(conversationControllerProvider).syncMessagesFromServer();
      targetId =
          _ref
              .read(conversationControllerProvider)
              .resolveLatestUnreadConversationId() ??
          '';
    }

    if (targetId.isNotEmpty) {
      _pendingConversationId = targetId;
      _pendingOpenConversationList = false;
      _latestEventSummary = '通知点击待跳转会话: $targetId';
      notifyListeners();
    } else {
      _pendingConversationId = '';
      _pendingOpenConversationList = true;
      _latestEventSummary = '通知点击待跳转会话列表';
      notifyListeners();
    }

    if (_ref.read(accountProvider) == null) {
      _appendLog('未登录，先跳登录页，保留待跳转');
      _ref.read(appRouterProvider).go(AppRoutes.login);
      return;
    }

    await _performNavigation(
      targetId: targetId,
      openConversationList: targetId.isEmpty,
    );
  }

  Future<void> _performNavigation({
    required String targetId,
    required bool openConversationList,
  }) async {
    final router = _ref.read(appRouterProvider);
    if (targetId.isNotEmpty) {
      _pendingConversationId = '';
      _pendingOpenConversationList = false;
      _latestEventSummary = '跳转到会话: $targetId';
      notifyListeners();
      _appendLog('跳转会话: $targetId');
      // 先落到会话 Tab，再打开聊天页，避免 shell 路由上下文不稳。
      router.go(AppRoutes.conversation);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      router.push('${AppRoutes.conversation}/chat/$targetId');
      return;
    }

    if (openConversationList) {
      _pendingOpenConversationList = false;
      _latestEventSummary = '跳转到会话列表';
      notifyListeners();
      _appendLog('跳转会话列表');
      router.go(AppRoutes.conversation);
    }
  }

  String _readTargetId(Map<String, dynamic> payload) {
    return payload['targetid']?.toString().trim() ??
        payload['chatId']?.toString().trim() ??
        payload['other_userid']?.toString().trim() ??
        payload['userid']?.toString().trim() ??
        '';
  }

  Future<void> manualSyncMessages() async {
    _latestEventSummary = '手动同步消息中';
    notifyListeners();
    await _ref.read(conversationControllerProvider).syncMessagesFromServer();
    _latestEventSummary = '手动同步完成';
    notifyListeners();
    _appendLog('手动同步完成');
  }

  /// 「我的」联调面板：不发真推送，本地模拟一次点击跳转
  Future<void> simulateNotificationClick({
    String? targetId,
    bool needPull = true,
  }) async {
    final payload = <String, dynamic>{
      if (needPull) 'needpull': '1',
      if (targetId != null && targetId.trim().isNotEmpty)
        'targetid': targetId.trim(),
      'title': '联调模拟通知',
      'body': '模拟点击跳转',
    };
    _appendLog('模拟通知点击: ${jsonEncode(payload)}');
    await _handleBusinessPayload(payload);
    await _navigateFromPushData(payload, fromClick: true);
  }

  /// 取出并清空 pending，返回 go_router location；无 pending 返回 null
  String? consumePendingNavigationLocation() {
    final targetId = _pendingConversationId.trim();
    if (targetId.isNotEmpty) {
      _pendingConversationId = '';
      _pendingOpenConversationList = false;
      notifyListeners();
      return '${AppRoutes.conversation}/chat/$targetId';
    }
    if (_pendingOpenConversationList) {
      _pendingOpenConversationList = false;
      notifyListeners();
      return AppRoutes.conversation;
    }
    return null;
  }

  void _sendFeedbackIfPossible(Map<String, dynamic> message) {
    final taskId =
        message['taskId']?.toString() ?? message['taskid']?.toString() ?? '';
    final messageId =
        message['messageId']?.toString() ??
        message['messageid']?.toString() ??
        '';
    if (taskId.isEmpty || messageId.isEmpty) {
      return;
    }
    try {
      _plugin.sendFeedbackMessage(taskId, messageId, 90001);
      _appendLog('已回执 feedback: taskId=$taskId messageId=$messageId');
    } catch (error) {
      _appendLog('回执失败: $error');
    }
  }

  void _captureRawEvent(String name, Map<String, dynamic> message) {
    _lastRawEvent = Map<String, dynamic>.from(message);
    _appendLog('$name: ${jsonEncode(message)}');
    _latestEventSummary = name;
    notifyListeners();
  }

  void _appendLog(String message) {
    final stamp = DateTime.now().toIso8601String().substring(11, 19);
    final line = '[$stamp] $message';
    _eventLogs.insert(0, line);
    if (_eventLogs.length > _maxEventLogs) {
      _eventLogs.removeRange(_maxEventLogs, _eventLogs.length);
    }
    _logger.d('[Getui] $message');
    notifyListeners();
  }

  Future<dynamic> _noopMap(Map<String, dynamic> message) async {
    _appendLog('ignored event: ${jsonEncode(message)}');
  }
}
