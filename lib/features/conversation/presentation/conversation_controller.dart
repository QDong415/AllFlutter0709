import 'dart:async';
import 'dart:io';

import 'package:all_flutter0709/core/account/account.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/features/conversation/data/conversation_repository.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final conversationControllerProvider = Provider<ConversationController>((ref) {
  final controller = ConversationController(ref);
  unawaited(controller.initialize());
  ref.onDispose(controller.dispose);
  return controller;
});

class ConversationController extends ChangeNotifier {
  ConversationController(this._ref);

  final Ref _ref;

  AsyncValue<List<ConversationSummary>> conversationsState =
      const AsyncValue.loading();
  final Map<String, AsyncValue<List<ConversationMessage>>> _messagesState = {};

  bool _initialized = false;
  bool _syncing = false;
  int _totalUnreadCount = 0;
  String? _activeConversationId;

  int get totalUnreadCount => _totalUnreadCount;

  AsyncValue<List<ConversationMessage>> messagesStateOf(String conversationId) {
    return _messagesState[conversationId] ?? const AsyncValue.loading();
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    await refreshConversations();
  }

  Future<void> refreshConversations() async {
    final account = _ref.read(accountProvider);
    if (account == null) {
      conversationsState = const AsyncValue.data(<ConversationSummary>[]);
      _totalUnreadCount = 0;
      notifyListeners();
      return;
    }

    if (!conversationsState.hasValue) {
      conversationsState = const AsyncValue.loading();
      notifyListeners();
    }

    try {
      final repository = _ref.read(conversationRepositoryProvider);
      final conversations = await repository.getConversationList(
        account.userId,
      );
      final unreadCount = await repository.getTotalUnreadCount(account.userId);
      conversationsState = AsyncValue.data(conversations);
      _totalUnreadCount = unreadCount;
      notifyListeners();
    } catch (error, stackTrace) {
      conversationsState = AsyncValue.error(error, stackTrace);
      notifyListeners();
    }
  }

  Future<void> ensureMessagesLoaded(String conversationId) async {
    final state = _messagesState[conversationId];
    if (state is AsyncData<List<ConversationMessage>> &&
        state.value.isNotEmpty) {
      return;
    }
    await refreshMessages(conversationId);
  }

  Future<void> refreshMessages(String conversationId) async {
    final account = _ref.read(accountProvider);
    if (account == null) {
      _messagesState[conversationId] = const AsyncValue.data(
        <ConversationMessage>[],
      );
      notifyListeners();
      return;
    }

    _messagesState[conversationId] = const AsyncValue.loading();
    notifyListeners();
    try {
      final repository = _ref.read(conversationRepositoryProvider);
      final messages = await repository.getMessages(
        account.userId,
        conversationId,
      );
      _messagesState[conversationId] = AsyncValue.data(messages);
      notifyListeners();
    } catch (error, stackTrace) {
      _messagesState[conversationId] = AsyncValue.error(error, stackTrace);
      notifyListeners();
    }
  }

  Future<void> openConversation(String conversationId) async {
    _activeConversationId = conversationId;
    await ensureMessagesLoaded(conversationId);
    await markConversationRead(conversationId);
  }

  void closeConversation(String conversationId) {
    if (_activeConversationId == conversationId) {
      _activeConversationId = null;
    }
  }

  Future<void> markConversationRead(String conversationId) async {
    final account = _ref.read(accountProvider);
    if (account == null) {
      return;
    }
    final repository = _ref.read(conversationRepositoryProvider);
    await repository.markConversationRead(account.userId, conversationId);
    await refreshMessages(conversationId);
    await refreshConversations();
  }

  Future<void> syncMessagesFromServer() async {
    if (_syncing) {
      return;
    }

    final account = _ref.read(accountProvider);
    if (account == null) {
      return;
    }

    _syncing = true;
    try {
      final repository = _ref.read(conversationRepositoryProvider);
      await repository.syncPulledMessages(account.userId);
      if (_activeConversationId case final activeId?) {
        await repository.markConversationRead(account.userId, activeId);
        await refreshMessages(activeId);
      }
      await refreshConversations();
    } finally {
      _syncing = false;
    }
  }

  /// 推送无 targetid 时：优先最近有未读的会话。
  String? resolveLatestUnreadConversationId() {
    final conversations = conversationsState.asData?.value;
    if (conversations == null || conversations.isEmpty) {
      return null;
    }
    final unread = conversations
        .where((item) => item.unreadCount > 0)
        .toList(growable: false);
    if (unread.isEmpty) {
      return null;
    }
    unread.sort(
      (a, b) => b.latestTimeSeconds.compareTo(a.latestTimeSeconds),
    );
    return unread.first.conversationId;
  }

  Future<void> sendTextMessage({
    required String conversationId,
    required String text,
    String peerName = '',
    String peerAvatar = '',
  }) async {
    final account = _ref.read(accountProvider);
    if (account == null) {
      throw Exception('请先登录');
    }
    final repository = _ref.read(conversationRepositoryProvider);
    final message = await repository.createPendingTextMessage(
      account: account,
      conversationId: conversationId,
      text: text,
      peerName: peerName,
      peerAvatar: peerAvatar,
    );
    await _appendAndNotify(conversationId, message);
    await refreshConversations();

    try {
      await repository.sendPendingTextMessage(
        account: account,
        message: message,
      );
    } finally {
      await refreshMessages(conversationId);
      await refreshConversations();
    }
  }

  Future<void> sendImageMessage({
    required String conversationId,
    required File imageFile,
    required Size imageSize,
    String peerName = '',
    String peerAvatar = '',
  }) async {
    final account = _ref.read(accountProvider);
    if (account == null) {
      throw Exception('请先登录');
    }
    final repository = _ref.read(conversationRepositoryProvider);
    final message = await repository.createPendingImageMessage(
      account: account,
      conversationId: conversationId,
      imageFile: imageFile,
      imageSize: imageSize,
      peerName: peerName,
      peerAvatar: peerAvatar,
    );
    await _appendAndNotify(conversationId, message);
    await refreshConversations();

    try {
      await repository.sendPendingImageMessage(
        account: account,
        message: message,
      );
    } finally {
      await refreshMessages(conversationId);
      await refreshConversations();
    }
  }

  Future<void> syncPushClientId(String clientId) async {
    final account = _ref.read(accountProvider);
    if (account == null || clientId.trim().isEmpty || account.cid == clientId) {
      return;
    }

    final repository = _ref.read(conversationRepositoryProvider);
    await repository.updatePushClientId(clientId: clientId, account: account);
    final nextAccount = account.copyWith(cid: clientId);
    await _ref.read(accountProvider.notifier).setAccount(nextAccount);
  }

  /// 【入口 A】运行期登录 / 退出后调用（见 GetuiPushService 的 ref.listen）。
  Future<void> onLoginStateChanged(AccountModel? account) async {
    await _refreshList(account);
  }

  /// 【入口 B】个推 / App 初始化完成后，用「当前已恢复的登录态」补一次。
  /// 与 [onLoginStateChanged] 共用 [_refreshList]，仅语义入口不同。
  Future<void> checkedLoginStateAfterInitedApp(AccountModel? account) async {
    await _refreshList(account);
  }

  /// 按登录态刷新会话：未登录清空内存；已登录拉本地列表并 message/pull。
  Future<void> _refreshList(AccountModel? account) async {
    if (account == null) {
      conversationsState = const AsyncValue.data(<ConversationSummary>[]);
      _messagesState.clear();
      _totalUnreadCount = 0;
      _activeConversationId = null;
      notifyListeners();
      return;
    }
    await refreshConversations();
    await syncMessagesFromServer();
  }

  Future<void> _appendAndNotify(
    String conversationId,
    ConversationMessage message,
  ) async {
    final currentState = _messagesState[conversationId];
    final currentMessages = currentState is AsyncData<List<ConversationMessage>>
        ? currentState.value
        : const <ConversationMessage>[];
    _messagesState[conversationId] = AsyncValue.data(
      List<ConversationMessage>.from(currentMessages)..add(message),
    );
    notifyListeners();
  }
}
