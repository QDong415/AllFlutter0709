import 'dart:async';
import 'dart:io';

import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_message.dart';
import 'package:all_flutter0709/features/conversation/data/models/conversation_summary.dart';
import 'package:all_flutter0709/features/conversation/presentation/chat_image_preview_page.dart';
import 'package:all_flutter0709/features/conversation/presentation/conversation_controller.dart';
import 'package:all_flutter0709/features/conversation/presentation/mappers/chat_item_mapper.dart';
import 'package:all_flutter0709/features/conversation/presentation/models/chat_item.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_input_bar.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_list_item_widget.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// 单聊页；未登录时拦截并跳转登录，不加载会话消息。
class ConversationChatPage extends ConsumerStatefulWidget {
  const ConversationChatPage({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<ConversationChatPage> createState() =>
      _ConversationChatPageState();
}

class _ConversationChatPageState extends ConsumerState<ConversationChatPage> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();

  final bool _isVoiceMode = false;
  bool _isPanelVisible = false;
  bool _isRecording = false;
  bool _willCancelRecording = false;
  bool _isSubmitting = false;
  int _recordDurationSeconds = 0;
  double _currentAmplitude = -45;

  Timer? _recordTimer;
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 未登录时 push 登录页；勿再 pop，否则会把刚打开的登录页关掉。
      if (!context.ensureLoggedIn()) {
        return;
      }
      unawaited(
        ref
            .read(conversationControllerProvider)
            .openConversation(widget.chatId),
      );
    });
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    unawaited(_amplitudeSubscription?.cancel());
    unawaited(_audioRecorder.dispose());
    ref.read(conversationControllerProvider).closeConversation(widget.chatId);
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus && _isPanelVisible) {
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

    setState(() {
      _isPanelVisible = !_isPanelVisible;
    });
    _focusNode.unfocus();
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
      await ref
          .read(conversationControllerProvider)
          .sendTextMessage(conversationId: widget.chatId, text: text);
      _textController.clear();
      _scrollToBottom();
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

    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    if (pickedFile == null) {
      return;
    }

    final imageFile = File(pickedFile.path);
    final imageSize = await _readImageSize(imageFile);

    setState(() {
      _isSubmitting = true;
      _isPanelVisible = false;
    });
    _focusNode.unfocus();

    try {
      await ref
          .read(conversationControllerProvider)
          .sendImageMessage(
            conversationId: widget.chatId,
            imageFile: imageFile,
            imageSize: imageSize,
          );
      _scrollToBottom();
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

    final permissionStatus = await Permission.microphone.request();
    if (!permissionStatus.isGranted) {
      if (!mounted) {
        return;
      }

      _showSnackBar(
        permissionStatus.isPermanentlyDenied ? '请在系统设置中开启麦克风权限' : '需要麦克风权限才能录音',
      );
      return;
    }

    final path =
        '${Directory.systemTemp.path}'
        '${Platform.pathSeparator}'
        'chat_record_${DateTime.now().millisecondsSinceEpoch}.m4a';

    try {
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          numChannels: 1,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );
    } catch (_) {
      if (mounted) {
        _showSnackBar('录音启动失败');
      }
      return;
    }

    _recordTimer?.cancel();
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 180))
        .listen((amplitude) {
          if (!mounted) {
            return;
          }
          setState(() {
            _currentAmplitude = amplitude.current;
          });
        });

    setState(() {
      _isRecording = true;
      _willCancelRecording = false;
      _recordDurationSeconds = 0;
      _currentAmplitude = -45;
      _isPanelVisible = false;
    });
    _focusNode.unfocus();

    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isRecording) {
        return;
      }
      setState(() {
        _recordDurationSeconds++;
      });
    });
  }

  void _handleVoiceLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_isRecording) {
      return;
    }

    final shouldCancel = details.offsetFromOrigin.dy < -60;
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

    _recordTimer?.cancel();
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;

    setState(() {
      _isRecording = false;
      _willCancelRecording = false;
      _currentAmplitude = -45;
      _recordDurationSeconds = 0;
    });

    if (shouldCancel) {
      await _audioRecorder.cancel();
      return;
    }

    await _audioRecorder.stop();
    if (!mounted) {
      return;
    }

    _showSnackBar('当前先接通文本、图片和推送同步，语音发送稍后补。');
  }

  Future<Size> _readImageSize(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = await decodeImageFromList(bytes);
      final size = Size(image.width.toDouble(), image.height.toDouble());
      image.dispose();
      return size;
    } catch (_) {
      return const Size(1080, 1439);
    }
  }

  void _openImagePreview(ImageMessage tappedItem, List<ChatItem> items) {
    final imageItems = items.whereType<ImageMessage>().toList(growable: false);
    final initialIndex = imageItems.indexOf(tappedItem);
    if (initialIndex < 0) {
      return;
    }

    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (context, animation, secondaryAnimation) {
          return ChatImagePreviewPage(
            images: imageItems,
            initialIndex: initialIndex,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          final scale = Tween<double>(begin: 0.96, end: 1.0).animate(fade);
          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(conversationControllerProvider);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.messagesStateOf(widget.chatId);
        final messages = state is AsyncData<List<ConversationMessage>>
            ? state.value
            : const <ConversationMessage>[];
        final items = buildChatItems(messages);
        final conversations =
            controller.conversationsState.asData?.value ??
            const <ConversationSummary>[];
        String? conversationName;
        for (final item in conversations) {
          if (item.conversationId == widget.chatId) {
            conversationName = item.name;
            break;
          }
        }

        if (state.hasValue && items.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }

        return Scaffold(
          appBar: CommonAppBar(
            title: conversationName?.isNotEmpty == true
                ? conversationName!
                : '会话 ${widget.chatId}',
            actions: const [SizedBox(width: 12)],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: state.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stackTrace) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded),
                              const SizedBox(height: 12),
                              Text(
                                error.toString(),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              FilledButton.tonal(
                                onPressed: () {
                                  unawaited(
                                    ref
                                        .read(conversationControllerProvider)
                                        .syncMessagesFromServer(),
                                  );
                                },
                                child: const Text('重试'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      data: (messages) {
                        if (messages.isEmpty) {
                          return RefreshIndicator(
                            onRefresh: () => ref
                                .read(conversationControllerProvider)
                                .syncMessagesFromServer(),
                            child: ListView(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                12,
                                12,
                                16,
                              ),
                              children: const [
                                SizedBox(height: 160),
                                Center(child: Text('还没有消息，发一条开始聊天吧')),
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () => ref
                              .read(conversationControllerProvider)
                              .syncMessagesFromServer(),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              return ChatListItemWidget(
                                item: items[index],
                                onImageTap: (image) =>
                                    _openImagePreview(image, items),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  ChatInputBar(
                    isVoiceMode: _isVoiceMode,
                    isPanelVisible: _isPanelVisible,
                    isRecording: _isRecording,
                    willCancelRecording: _willCancelRecording,
                    recordingDurationText: _recordDurationLabel,
                    controller: _textController,
                    focusNode: _focusNode,
                    onToggleVoiceMode: _toggleVoiceMode,
                    onTogglePanel: _togglePanel,
                    onSendText: () {
                      unawaited(_sendText());
                    },
                    onSendImage: () {
                      unawaited(_sendImage());
                    },
                    onVoiceLongPressStart: (details) {
                      unawaited(_handleVoiceLongPressStart(details));
                    },
                    onVoiceLongPressMoveUpdate: _handleVoiceLongPressMoveUpdate,
                    onVoiceLongPressEnd: (details) {
                      unawaited(_handleVoiceLongPressEnd(details));
                    },
                  ),
                ],
              ),
              if (_isRecording)
                Positioned.fill(
                  child: IgnorePointer(
                    child: _RecordingOverlay(
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

  String get _recordDurationLabel {
    final minutes = (_recordDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordDurationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _RecordingOverlay extends StatelessWidget {
  const _RecordingOverlay({
    required this.isCancelling,
    required this.seconds,
    required this.amplitude,
  });

  final bool isCancelling;
  final int seconds;
  final double amplitude;

  @override
  Widget build(BuildContext context) {
    final normalized = ((amplitude + 45) / 45).clamp(0.0, 1.0);

    return Center(
      child: Container(
        width: 156,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: BoxDecoration(
          color: isCancelling
              ? const Color(0xCCB3261E)
              : const Color(0xB2000000),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCancelling ? Icons.delete_outline_rounded : Icons.mic_rounded,
              size: 42,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(4, (index) {
                final factor = (normalized * (0.5 + index * 0.18)).clamp(
                  0.2,
                  1.0,
                );
                return Container(
                  width: 6,
                  height: 10 + 18 * factor,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Text(
              '$seconds"',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCancelling ? '松开手指，取消发送' : '手指上滑，取消发送',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
