import 'dart:async';
import 'dart:io';

import 'package:all_flutter0709/core/account/account.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/core/push/chat_push_log.dart';
import 'package:all_flutter0709/features/conversation/data/conversation_repository.dart';
import 'package:all_flutter0709/features/conversation/data/remind_unread_store.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_summary.dart';
import 'package:all_flutter0709/features/conversation/presentation/controllers/chat_send_coordinator.dart';
import 'package:all_flutter0709/features/conversation/presentation/controllers/conversation_message_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final conversationControllerProvider = Provider<ConversationController>((ref) {
  final controller = ConversationController(ref);
  unawaited(controller.initialize());
  ref.onDispose(controller.dispose);
  return controller;
});

class ConversationController extends ChangeNotifier {
  ConversationController(this._ref) {
    _remindUnreadStore = _ref.read(remindUnreadStoreProvider);
    _remindUnreadStore.addListener(_onRemindStoreChanged);
    _sendCoordinator = ChatSendCoordinator(
      repository: _ref.read(conversationRepositoryProvider),
      messageStore: _messageStore,
      refreshConversations: refreshConversations,
    );
  }

  final Ref _ref;
  late final RemindUnreadStore _remindUnreadStore;
  final ConversationMessageStore _messageStore = ConversationMessageStore();
  late final ChatSendCoordinator _sendCoordinator;

  AsyncValue<List<ConversationSummary>> conversationsState =
      const AsyncValue.loading();

  bool _initialized = false;
  bool _syncing = false;
  int _totalUnreadCount = 0;
  int _remindUnreadCount = 0;
  String? _activeConversationId;

  /// 聊天未读 + 赞/评论/粉丝/@我 未读。
  int get totalUnreadCount => _totalUnreadCount + _remindUnreadCount;

  /// 某一类动态提醒的未读数。
  int remindUnreadCount(RemindKind kind) {
    final userId = _ref.read(accountProvider)?.userId ?? '';
    return _remindUnreadStore.countOf(userId: userId, kind: kind);
  }

  AsyncValue<List<ConversationMessage>> messagesStateOf(String conversationId) {
    return _messageStore.stateOf(conversationId);
  }

  /// 监听指定会话的消息，避免会话列表和未读数变化时重建聊天页。
  ValueListenable<AsyncValue<List<ConversationMessage>>> messagesListenableOf(
    String conversationId,
  ) {
    return _messageStore.listenableOf(conversationId);
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
      _remindUnreadCount = 0;
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
      _syncRemindUnread(notify: false);
      notifyListeners();
    } catch (error, stackTrace) {
      conversationsState = AsyncValue.error(error, stackTrace);
      notifyListeners();
    }
  }

  void _onRemindStoreChanged() {
    _syncRemindUnread();
  }

  void _syncRemindUnread({bool notify = true}) {
    final userId = _ref.read(accountProvider)?.userId ?? '';
    final count = userId.isEmpty ? 0 : _remindUnreadStore.totalOf(userId);
    if (_remindUnreadCount == count) {
      return;
    }
    _remindUnreadCount = count;
    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _remindUnreadStore.removeListener(_onRemindStoreChanged);
    _messageStore.dispose();
    super.dispose();
  }

  Future<void> ensureMessagesLoaded(String conversationId) async {
    final state = messagesStateOf(conversationId);
    if (state is AsyncData<List<ConversationMessage>> &&
        state.value.isNotEmpty) {
      return;
    }
    await refreshMessages(conversationId);
  }

  Future<void> refreshMessages(String conversationId) async {
    final account = _ref.read(accountProvider);
    if (account == null) {
      _messageStore.setState(
        conversationId,
        const AsyncValue.data(<ConversationMessage>[]),
      );
      return;
    }

    final previousState = messagesStateOf(conversationId);
    final hasPreviousData =
        previousState is AsyncData<List<ConversationMessage>>;
    // 只有首次加载才用整页 loading。后台同步、发送完成和标记已读时保留
    // 当前消息，避免列表被 loading 短暂替换后整棵重新挂载而闪烁。
    if (!hasPreviousData) {
      _messageStore.setState(conversationId, const AsyncValue.loading());
    }
    try {
      final repository = _ref.read(conversationRepositoryProvider);
      final messages = await repository.getMessages(
        account.userId,
        conversationId,
      );
      _messageStore.setState(conversationId, AsyncValue.data(messages));
    } catch (error, stackTrace) {
      if (!hasPreviousData) {
        _messageStore.setState(
          conversationId,
          AsyncValue.error(error, stackTrace),
        );
      } else {
        ChatPushLog.d('后台刷新消息失败，保留当前列表: $error');
      }
    }
  }

  Future<void> openConversation(String conversationId) async {
    _activeConversationId = conversationId;
    ChatPushLog.d('openConversation: $conversationId');
    await ensureMessagesLoaded(conversationId);
    final account = _ref.read(accountProvider);
    if (account != null) {
      final repository = _ref.read(conversationRepositoryProvider);
      final messages = await repository.getMessages(
        account.userId,
        conversationId,
      );
      await repository.ensureLocalVoiceFiles(account.userId, messages);
      await refreshMessages(conversationId);
    }
    await markConversationRead(conversationId);
  }

  void closeConversation(String conversationId) {
    if (_activeConversationId == conversationId) {
      _activeConversationId = null;
      ChatPushLog.d('closeConversation: $conversationId（已清除 active）');
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

  /// 删除本地会话及其消息，并刷新列表与未读数。
  Future<void> deleteConversation(String conversationId) async {
    final account = _ref.read(accountProvider);
    if (account == null) {
      return;
    }
    final id = conversationId.trim();
    if (id.isEmpty) {
      return;
    }

    final repository = _ref.read(conversationRepositoryProvider);
    await repository.deleteConversation(account.userId, id);
    _messageStore.setState(id, const AsyncValue.data(<ConversationMessage>[]));
    if (_activeConversationId == id) {
      _activeConversationId = null;
    }
    await refreshConversations();
  }

  /// 删除单条本地消息并刷新当前会话列表。
  Future<void> deleteMessage({
    required String conversationId,
    required int clientMessageId,
    required int msgId,
  }) async {
    final account = _ref.read(accountProvider);
    if (account == null) {
      return;
    }
    final repository = _ref.read(conversationRepositoryProvider);
    await repository.deleteMessage(
      userId: account.userId,
      clientMessageId: clientMessageId,
      msgId: msgId,
    );

    _messageStore.remove(
      conversationId: conversationId,
      clientMessageId: clientMessageId,
      msgId: msgId,
    );
    await refreshConversations();
  }

  /// 撤回自己发出的消息，成功后把当前列表里的那条改成居中提示。
  Future<void> recallMessage({
    required String conversationId,
    required int clientMessageId,
    required int msgId,
  }) async {
    final account = _ref.read(accountProvider);
    if (account == null) {
      throw Exception('请先登录');
    }
    final repository = _ref.read(conversationRepositoryProvider);
    await repository.recallMessage(
      userId: account.userId,
      clientMessageId: clientMessageId,
      msgId: msgId,
    );

    _messageStore.updateByIdentity(
      conversationId: conversationId,
      clientMessageId: clientMessageId,
      msgId: msgId,
      transform: (message) => message.copyWith(
        messageType: ConversationMessageType.recall,
        content: '',
        filename: '',
        extend: '',
        localFilePath: '',
        uploadProgress: 0,
      ),
    );
    await refreshConversations();
  }

  Future<void> syncMessagesFromServer() async {
    if (_syncing) {
      ChatPushLog.d('syncMessagesFromServer 跳过：已在同步中');
      return;
    }

    final account = _ref.read(accountProvider);
    if (account == null) {
      ChatPushLog.d('syncMessagesFromServer 跳过：未登录');
      return;
    }

    _syncing = true;
    ChatPushLog.d(
      'syncMessagesFromServer 开始 userId=${account.userId} '
      'activeConversationId=$_activeConversationId',
    );
    try {
      final repository = _ref.read(conversationRepositoryProvider);
      final inserted = await repository.syncPulledMessages(account.userId);
      // 先刷新未读角标；只有「当前正在看的会话」才标已读，
      // 避免离开聊天页后 activeId 残留导致新消息被立刻标已读、主页角标一直为 0。
      await refreshConversations();
      ChatPushLog.d(
        'sync 后未读=$_totalUnreadCount inserted=$inserted '
        'active=$_activeConversationId',
      );

      if (_activeConversationId case final activeId?) {
        ChatPushLog.d('正在查看会话，标记已读: $activeId');
        await repository.markConversationRead(account.userId, activeId);
        await refreshMessages(activeId);
        await refreshConversations();
      }

      final unread = _totalUnreadCount;
      final count = conversationsState.asData?.value.length ?? 0;
      ChatPushLog.d(
        'syncMessagesFromServer 完成 conversations=$count unread=$unread',
      );
    } catch (error, stackTrace) {
      ChatPushLog.d('syncMessagesFromServer 失败: $error');
      ChatPushLog.d('$stackTrace');
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
    unread.sort((a, b) => b.latestTimeSeconds.compareTo(a.latestTimeSeconds));
    return unread.first.conversationId;
  }

  Future<void> sendTextMessage({
    required String conversationId,
    required String text,
    String peerName = '',
    String peerAvatar = '',
    int peerUserType = 0,
  }) async {
    final account = _ref.read(accountProvider);
    if (account == null) {
      throw Exception('请先登录');
    }
    await _sendCoordinator.sendText(
      account: account,
      conversationId: conversationId,
      text: text,
      peerName: peerName,
      peerAvatar: peerAvatar,
      peerUserType: peerUserType,
    );
  }

  Future<void> sendImageMessage({
    required String conversationId,
    required File imageFile,
    required Size imageSize,
    String peerName = '',
    String peerAvatar = '',
    int peerUserType = 0,
  }) async {
    final account = _ref.read(accountProvider);
    if (account == null) {
      throw Exception('请先登录');
    }
    await _sendCoordinator.sendImage(
      account: account,
      conversationId: conversationId,
      imageFile: imageFile,
      imageSize: imageSize,
      peerName: peerName,
      peerAvatar: peerAvatar,
      peerUserType: peerUserType,
    );
  }

  /// 发送语音：先落本地 pending，再上传七牛并 `/api/chat/send`。
  Future<void> sendVoiceMessage({
    required String conversationId,
    required File audioFile,
    required String filename,
    required int durationSeconds,
    String peerName = '',
    String peerAvatar = '',
    int peerUserType = 0,
  }) async {
    final account = _ref.read(accountProvider);
    if (account == null) {
      throw Exception('请先登录');
    }
    await _sendCoordinator.sendVoice(
      account: account,
      conversationId: conversationId,
      audioFile: audioFile,
      filename: filename,
      durationSeconds: durationSeconds,
      peerName: peerName,
      peerAvatar: peerAvatar,
      peerUserType: peerUserType,
    );
  }

  /// 标记语音已播放并刷新当前会话。
  Future<void> markVoicePlayed({
    required String conversationId,
    required int msgId,
    required int durationSeconds,
  }) async {
    final account = _ref.read(accountProvider);
    if (account == null || msgId <= 0) {
      return;
    }
    final repository = _ref.read(conversationRepositoryProvider);
    await repository.markVoicePlayed(
      userId: account.userId,
      msgId: msgId,
      durationSeconds: durationSeconds,
    );

    final extend = ConversationMessage.voiceExtendJson(
      durationSeconds: durationSeconds,
      hadPlay: true,
    );
    _messageStore.updateByIdentity(
      conversationId: conversationId,
      clientMessageId: 0,
      msgId: msgId,
      transform: (message) => message.copyWith(extend: extend),
    );
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
      _messageStore.clearAll();
      _totalUnreadCount = 0;
      _activeConversationId = null;
      notifyListeners();
      return;
    }
    await refreshConversations();
    await syncMessagesFromServer();
  }
}
