import 'dart:async';

import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_summary.dart';
import 'package:all_flutter0709/features/conversation/presentation/conversation_controller.dart';
import 'package:all_flutter0709/features/conversation/presentation/helpers/chat_image_preview_helper.dart';
import 'package:all_flutter0709/features/conversation/presentation/helpers/chat_scroll_helper.dart';
import 'package:all_flutter0709/features/conversation/presentation/helpers/chat_send_helper.dart';
import 'package:all_flutter0709/features/conversation/presentation/helpers/chat_voice_record_helper.dart';
import 'package:all_flutter0709/features/conversation/presentation/mappers/chat_item_mapper.dart';
import 'package:all_flutter0709/features/conversation/presentation/models/chat_item.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_input_bar.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_message_list_view.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_recording_overlay.dart';
import 'package:all_flutter0709/features/user/presentation/helpers/user_detail_navigation.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _ConversationChatPageState extends ConsumerState<ConversationChatPage>
    with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _sendHelper = ChatSendHelper();
  final _imagePreviewHelper = const ChatImagePreviewHelper();
  late final ChatScrollHelper _scrollHelper;
  late final ChatVoiceRecordHelper _voiceRecordHelper;

  /// 在 dispose 里不能依赖 ref，提前拿到 controller 以便可靠清除 active 会话。
  ConversationController? _conversationController;

  final bool _isVoiceMode = false;
  bool _isPanelVisible = false;
  bool _isRecording = false;
  bool _willCancelRecording = false;
  bool _isSubmitting = false;
  int _recordDurationSeconds = 0;
  double _currentAmplitude = -45;

  /// 已记录的软键盘高度；面板打开期间锁定，不随收键盘动画缩小（对齐 iTopicX FuncLayout）。
  static const double _defaultKeyboardHeight = 280;
  double _recordedKeyboardHeight = _defaultKeyboardHeight;
  double _bottomInset = 0;
  int _lastTextLength = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollHelper = ChatScrollHelper(_scrollController);
    _voiceRecordHelper = ChatVoiceRecordHelper();
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
    WidgetsBinding.instance.removeObserver(this);
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

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
      final keyboardJustOpened = bottomInset > 0 && _bottomInset <= 0;
      final insetChanged = (bottomInset - _bottomInset).abs() > 0.5;

      if (!insetChanged) {
        return;
      }

      setState(() {
        _bottomInset = bottomInset;
        // 仅在「未开面板」时更新记录高度。面板显示中若跟着 inset 缩小，
        // 扩展栏会在收键盘动画里被压没（视频里的 bug）。
        if (bottomInset > 0 && !_isPanelVisible) {
          _recordedKeyboardHeight = bottomInset;
        }
      });

      if (keyboardJustOpened || (bottomInset > 0 && !_isPanelVisible)) {
        _scrollHelper.scrollToBottom();
      }
    });
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      // 点输入框：收起“+”面板，让出软键盘占位（对齐 iTopicX）。
      if (_isPanelVisible) {
        setState(() {
          _isPanelVisible = false;
        });
      }
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

  /// 收起键盘与“+”面板（对齐 iTopicX ekBar.reset）。
  void _resetInputState() {
    if (!_focusNode.hasFocus && !_isPanelVisible) {
      return;
    }
    _focusNode.unfocus();
    if (_isPanelVisible) {
      setState(() {
        _isPanelVisible = false;
      });
    }
  }

  void _toggleVoiceMode() {
    if (_isRecording || _isSubmitting) {
      return;
    }

    _showSnackBar('已按 iTopicX 链路补齐文本和图片，语音消息旧工程未提供服务端协议。');
  }

  void _togglePanel() {
    if (_isRecording || _isSubmitting) {
      return;
    }

    if (_isPanelVisible) {
      setState(() {
        _isPanelVisible = false;
      });
      return;
    }

    // 打开面板：锁定当前键盘高度作占位，再收键盘（对齐 iTopicX toggleFuncView）。
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    setState(() {
      if (inset > 0) {
        _recordedKeyboardHeight = inset;
        _bottomInset = inset;
      } else if (_recordedKeyboardHeight < 200) {
        _recordedKeyboardHeight = _defaultKeyboardHeight;
      }
      _isPanelVisible = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _focusNode.unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      _scrollHelper.scrollToBottom();
    });
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
      _isPanelVisible = false;
    });
    _focusNode.unfocus();

    try {
      await _sendHelper.sendImage(
        controller: ref.read(conversationControllerProvider),
        conversationId: widget.chatId,
        imageFile: imageFile,
        imageSize: imageSize,
      );
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
      _isPanelVisible = false;
    });
    _focusNode.unfocus();
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

  /// 解析对方展示昵称/头像：会话列表 > 消息 otherName > 路由预填 > 「用户+ID」。
  ({String name, String avatar}) _resolvePeerDisplay({
    required String chatId,
    required List<ConversationSummary> conversations,
    required List<ConversationMessage> messages,
    String? initialPeerName,
    String? initialPeerAvatar,
  }) {
    final fallbackName = '用户$chatId';
    var name = '';
    var avatar = '';

    for (final item in conversations) {
      if (item.conversationId == chatId) {
        name = item.name.trim();
        avatar = item.avatar.trim();
        break;
      }
    }

    if (name.isEmpty || name == fallbackName) {
      for (final message in messages.reversed) {
        final otherName = message.otherName.trim();
        if (otherName.isNotEmpty && otherName != fallbackName) {
          name = otherName;
          break;
        }
      }
    }

    if (name.isEmpty || name == fallbackName) {
      final initialName = initialPeerName?.trim() ?? '';
      if (initialName.isNotEmpty) {
        name = initialName;
      }
    }

    if (avatar.isEmpty) {
      for (final message in messages.reversed) {
        final otherPhoto = message.otherPhoto.trim();
        if (otherPhoto.isNotEmpty) {
          avatar = otherPhoto;
          break;
        }
      }
    }

    if (avatar.isEmpty) {
      avatar = initialPeerAvatar?.trim() ?? '';
    }

    if (name.isEmpty) {
      name = fallbackName;
    }

    return (name: name, avatar: avatar);
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
        final conversations =
            controller.conversationsState.asData?.value ??
            const <ConversationSummary>[];
        final peer = _resolvePeerDisplay(
          chatId: widget.chatId,
          conversations: conversations,
          messages: messages,
          initialPeerName: widget.initialPeerName,
          initialPeerAvatar: widget.initialPeerAvatar,
        );
        final conversationName = peer.name;
        final peerAvatar = peer.avatar;
        final items = buildChatItems(
          messages,
          myAvatar: myAvatar,
          peerAvatar: peerAvatar,
        );

        if (state.hasValue && items.isNotEmpty) {
          _scrollHelper.scrollIfNewMessages(items.length);
        }

        // 不用 resizeToAvoidBottomInset：底部 Func 区在「键盘 inset / 面板高度」间切换，
        // 对齐 iTopicX SoftKeyboardSizeWatchLayout + FuncLayout。
        final funcAreaHeight = _isPanelVisible
            ? _recordedKeyboardHeight
            : _bottomInset;

        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: CommonAppBar(
            title: conversationName,
            actions: const [SizedBox(width: 12)],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _resetInputState,
                      behavior: HitTestBehavior.translucent,
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
                        onUserDragScroll: _resetInputState,
                        onImageTap: (image) {
                          _imagePreviewHelper.open(
                            context: context,
                            tappedItem: image,
                            items: items,
                          );
                        },
                        onAvatarTap: (message) {
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
                    isRecording: _isRecording,
                    willCancelRecording: _willCancelRecording,
                    recordingDurationText: _recordDurationLabel,
                    controller: _textController,
                    focusNode: _focusNode,
                    applyBottomSafeArea: funcAreaHeight <= 0,
                    onToggleVoiceMode: _toggleVoiceMode,
                    onTogglePanel: _togglePanel,
                    onSendText: () {
                      unawaited(_sendText());
                    },
                    onVoiceLongPressStart: (details) {
                      unawaited(_handleVoiceLongPressStart(details));
                    },
                    onVoiceLongPressMoveUpdate: _handleVoiceLongPressMoveUpdate,
                    onVoiceLongPressEnd: (details) {
                      unawaited(_handleVoiceLongPressEnd(details));
                    },
                  ),
                  // Func 占位：键盘弹出时为空（键盘盖住）；点「+」后填入扩展面板，高度不变。
                  SizedBox(
                    height: funcAreaHeight,
                    child: _isPanelVisible
                        ? ChatFuncPanel(
                            onSendImage: () {
                              unawaited(_sendImage());
                            },
                          )
                        : null,
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
        );
      },
    );
  }
}
