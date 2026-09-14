import 'dart:async';

import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/core/push/chat_push_log.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';
import 'package:all_flutter0709/features/conversation/presentation/conversation_controller.dart';
import 'package:all_flutter0709/features/conversation/presentation/helpers/chat_image_preview_helper.dart';
import 'package:all_flutter0709/features/conversation/presentation/helpers/chat_panel_helper.dart';
import 'package:all_flutter0709/features/conversation/presentation/helpers/chat_scroll_helper.dart';
import 'package:all_flutter0709/features/conversation/presentation/helpers/chat_send_helper.dart';
import 'package:all_flutter0709/features/conversation/presentation/helpers/chat_voice_record_helper.dart';
import 'package:all_flutter0709/features/conversation/presentation/mappers/chat_item_mapper.dart';
import 'package:all_flutter0709/features/conversation/presentation/models/chat_item.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_bottom_panel_host.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_input_bar.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_message_list_view.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_recording_overlay.dart';
import 'package:all_flutter0709/features/user/presentation/helpers/user_detail_navigation.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 单聊页；未登录时拦截并跳转登录，不加载会话消息。
class ConversationChatPage extends ConsumerStatefulWidget {
  const ConversationChatPage({
    super.key,
    required this.chatId,
    this.initialPeerName,
    this.initialPeerAvatar,
  });

  final String chatId;

  /// 路由预填的对方昵称（例如从个人主页「私信」进入）。
  final String? initialPeerName;

  /// 路由预填的对方头像。
  final String? initialPeerAvatar;

  @override
  ConsumerState<ConversationChatPage> createState() =>
      _ConversationChatPageState();
}

class _ConversationChatPageState extends ConsumerState<ConversationChatPage> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _sendHelper = ChatSendHelper();
  final _imagePreviewHelper = const ChatImagePreviewHelper();
  late final ChatScrollHelper _scrollHelper;
  late final ChatVoiceRecordHelper _voiceRecordHelper;
  late final ChatPanelHelper _panelHelper;

  /// 在 dispose 里不能依赖 ref，提前拿到 controller 以便可靠清除 active 会话。
  ConversationController? _conversationController;

  /// 对方昵称/头像：路由带什么就用什么。
  String get _peerName {
    final name = widget.initialPeerName?.trim() ?? '';
    return name.isEmpty ? '用户${widget.chatId}' : name;
  }

  String get _peerAvatar => widget.initialPeerAvatar?.trim() ?? '';

  bool _isVoiceMode = false;
  bool _isRecording = false;
  bool _willCancelRecording = false;
  bool _isSubmitting = false;
  int _recordDurationSeconds = 0;
  double _currentAmplitude = -45;
  int _lastTextLength = 0;

  @override
  void initState() {
    super.initState();
    _scrollHelper = ChatScrollHelper(_scrollController);
    _voiceRecordHelper = ChatVoiceRecordHelper();
    _panelHelper = ChatPanelHelper(
      inputFocusNode: _focusNode,
      onUpdate: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
    _conversationController = ref.read(conversationControllerProvider);
    _focusNode.addListener(_handleFocusChange);
    _textController.addListener(_handleTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 未登录时 push 登录页；勿再 pop，否则会把刚打开的登录页关掉。
      if (!context.ensureLoggedIn()) {
        return;
      }
      unawaited(_conversationController!.openConversation(widget.chatId));
    });
  }

  @override
  void dispose() {
    unawaited(_voiceRecordHelper.dispose());
    _conversationController?.closeConversation(widget.chatId);
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _textController
      ..removeListener(_handleTextChanged)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _scrollHelper.scrollToBottom();
    }
  }

  void _handleTextChanged() {
    final length = _textController.text.length;
    // 输入增高（换行）时跟底。
    if (length != _lastTextLength) {
      _lastTextLength = length;
      if (_focusNode.hasFocus) {
        _scrollHelper.scrollToBottom();
      }
    }
  }

  /// 收起键盘与自定义面板。
  void _resetInputState() {
    _panelHelper.hidePanel();
  }

  /// Android 系统返回：键盘或面板打开时先收起。
  bool get _blockAndroidBack {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    if (_isRecording) {
      return true;
    }
    return _panelHelper.isPanelOrKeyboardVisible;
  }

  void _toggleVoiceMode() {
    if (_isRecording || _isSubmitting) {
      return;
    }

    final nextVoiceMode = !_isVoiceMode;
    setState(() {
      _isVoiceMode = nextVoiceMode;
    });
    if (nextVoiceMode) {
      _panelHelper.hidePanel();
    } else {
      _panelHelper.updatePanelType(ChatPanelType.keyboard);
    }
    _scrollHelper.scrollToBottom();
  }

  void _toggleEmoji() {
    if (_isRecording || _isSubmitting) {
      return;
    }
    if (_isVoiceMode) {
      setState(() {
        _isVoiceMode = false;
      });
    }
    _panelHelper.handleEmojiBtnClick();
    _scrollHelper.scrollToBottom();
  }

  void _togglePanel() {
    if (_isRecording || _isSubmitting) {
      return;
    }
    if (_panelHelper.currentPanelType == ChatPanelType.tool) {
      if (_isVoiceMode) {
        _panelHelper.hidePanel();
      } else {
        _panelHelper.updatePanelType(ChatPanelType.keyboard);
      }
    } else {
      _panelHelper.updatePanelType(ChatPanelType.tool);
    }
    _scrollHelper.scrollToBottom();
  }

  void _insertEmoji(String emoji) {
    _panelHelper.insertText(textController: _textController, text: emoji);
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSubmitting) {
      return;
    }
    if (!context.ensureLoggedIn()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _sendHelper.sendText(
        controller: ref.read(conversationControllerProvider),
        conversationId: widget.chatId,
        text: text,
        peerName: _peerName,
        peerAvatar: _peerAvatar,
      );
      _textController.clear();
      // reverse 列表下新消息已在底部；仅 jump 校正，不做动画。
      _scrollHelper.forceScrollToBottom(itemCount: _currentItemCountHint());
    } catch (error) {
      _showSnackBar(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _sendImage() async {
    if (_isSubmitting) {
      return;
    }
    if (!context.ensureLoggedIn()) {
      return;
    }

    final imageFile = await _sendHelper.pickImageFile();
    if (imageFile == null) {
      return;
    }

    final imageSize = await _sendHelper.readImageSize(imageFile);

    setState(() {
      _isSubmitting = true;
    });
    _panelHelper.hidePanel();

    try {
      await _sendHelper.sendImage(
        controller: ref.read(conversationControllerProvider),
        conversationId: widget.chatId,
        imageFile: imageFile,
        imageSize: imageSize,
        peerName: _peerName,
        peerAvatar: _peerAvatar,
      );
      _scrollHelper.forceScrollToBottom(itemCount: _currentItemCountHint());
    } catch (error, stackTrace) {
      ChatSendLog.d('页面发图失败: $error');
      ChatSendLog.d('$stackTrace');
      _showSnackBar(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleVoiceLongPressStart(LongPressStartDetails details) async {
    if (_isRecording || _isSubmitting) {
      return;
    }

    final result = await _voiceRecordHelper.start(
      onAmplitude: (amplitude) {
        if (!mounted) {
          return;
        }
        setState(() {
          _currentAmplitude = amplitude;
        });
      },
      onTick: () {
        if (!mounted || !_isRecording) {
          return;
        }
        setState(() {
          _recordDurationSeconds++;
        });
      },
    );

    if (!mounted) {
      return;
    }

    if (!result.isSuccess) {
      _showSnackBar(result.errorMessage!);
      return;
    }

    setState(() {
      _isRecording = true;
      _willCancelRecording = false;
      _recordDurationSeconds = 0;
      _currentAmplitude = -45;
    });
    _panelHelper.hidePanel();
  }

  void _handleVoiceLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_isRecording) {
      return;
    }

    final shouldCancel = _voiceRecordHelper.shouldCancelFromMove(details);
    if (shouldCancel == _willCancelRecording) {
      return;
    }

    setState(() {
      _willCancelRecording = shouldCancel;
    });
  }

  Future<void> _handleVoiceLongPressEnd(LongPressEndDetails details) async {
    if (!_isRecording) {
      return;
    }

    final shouldCancel = _willCancelRecording;
    await _voiceRecordHelper.stop(cancel: shouldCancel);

    setState(() {
      _isRecording = false;
      _willCancelRecording = false;
      _currentAmplitude = -45;
      _recordDurationSeconds = 0;
    });

    if (shouldCancel || !mounted) {
      return;
    }

    _showSnackBar('当前先接通文本、图片和推送同步，语音发送稍后补。');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String get _recordDurationLabel {
    final minutes = (_recordDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordDurationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int _currentItemCountHint() {
    final state = ref
        .read(conversationControllerProvider)
        .messagesStateOf(widget.chatId);
    final messages = state is AsyncData<List<ConversationMessage>>
        ? state.value
        : const <ConversationMessage>[];
    return buildChatItems(messages).length;
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(conversationControllerProvider);
    final myAvatar = ref.watch(accountProvider)?.avatar ?? '';
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.messagesStateOf(widget.chatId);
        final messages = state is AsyncData<List<ConversationMessage>>
            ? state.value
            : const <ConversationMessage>[];
        final conversationName = _peerName;
        final peerAvatar = _peerAvatar;
        final items = buildChatItems(
          messages,
          myAvatar: myAvatar,
          peerAvatar: peerAvatar,
        );

        if (state.hasValue && items.isNotEmpty) {
          _scrollHelper.scrollIfNewMessages(items.length);
        }

        return PopScope(
          canPop: !_blockAndroidBack,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            _panelHelper.hidePanel();
          },
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: CommonAppBar(
              title: conversationName,
              actions: const [SizedBox(width: 12)],
              onLeadingPressed: () => Navigator.of(context).pop(),
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Listener(
                        behavior: HitTestBehavior.translucent,
                        onPointerDown: (_) => _resetInputState(),
                        child: ChatMessageListView(
                          state: state,
                          items: items,
                          scrollController: _scrollController,
                          onRefresh: () => ref
                              .read(conversationControllerProvider)
                              .syncMessagesFromServer(),
                          onRetry: () {
                            unawaited(
                              ref
                                  .read(conversationControllerProvider)
                                  .syncMessagesFromServer(),
                            );
                          },
                          onImageTap: (image) {
                            _panelHelper.hidePanel();
                            _imagePreviewHelper.open(
                              context: context,
                              tappedItem: image,
                              items: items,
                            );
                          },
                          onAvatarTap: (message) {
                            _panelHelper.hidePanel();
                            // 右侧为自己，左侧为对方；不在此处拦登录，由个人主页内操作再校验。
                            if (message.direction == MessageDirection.right) {
                              final account = ref.read(accountProvider);
                              openUserDetailPage(
                                context,
                                userId: account?.userId ?? widget.chatId,
                                name: account?.name,
                                avatar: account?.avatar,
                              );
                              return;
                            }
                            openUserDetailPage(
                              context,
                              userId: widget.chatId,
                              name: conversationName,
                              avatar: peerAvatar,
                            );
                          },
                        ),
                      ),
                    ),
                    ChatInputBar(
                      isVoiceMode: _isVoiceMode,
                      isEmojiPanel:
                          _panelHelper.currentPanelType == ChatPanelType.emoji,
                      isRecording: _isRecording,
                      willCancelRecording: _willCancelRecording,
                      recordingDurationText: _recordDurationLabel,
                      controller: _textController,
                      focusNode: _focusNode,
                      readOnly: _panelHelper.readOnly,
                      onToggleVoiceMode: _toggleVoiceMode,
                      onToggleEmoji: _toggleEmoji,
                      onTogglePanel: _togglePanel,
                      onInputPointerUp: _panelHelper.handleInputViewOnPointerUp,
                      onSendText: () {
                        unawaited(_sendText());
                      },
                      onVoiceLongPressStart: (details) {
                        unawaited(_handleVoiceLongPressStart(details));
                      },
                      onVoiceLongPressMoveUpdate:
                          _handleVoiceLongPressMoveUpdate,
                      onVoiceLongPressEnd: (details) {
                        unawaited(_handleVoiceLongPressEnd(details));
                      },
                    ),
                    ChatBottomPanelHost(
                      controller: _panelHelper.controller,
                      inputFocusNode: _focusNode,
                      onPanelTypeChange: (panelType, data) {
                        _panelHelper.onPanelTypeChange(panelType, data);
                        _scrollHelper.scrollToBottom();
                      },
                      onSendImage: () {
                        unawaited(_sendImage());
                      },
                      onEmojiTap: _insertEmoji,
                    ),
                  ],
                ),
                if (_isRecording)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ChatRecordingOverlay(
                        isCancelling: _willCancelRecording,
                        seconds: _recordDurationSeconds <= 0
                            ? 1
                            : _recordDurationSeconds,
                        amplitude: _currentAmplitude,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
