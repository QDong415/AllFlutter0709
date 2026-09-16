import 'dart:async';
import 'dart:math' as math;

import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/features/conversation/presentation/helpers/chat_panel_helper.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_emoji_panel.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_input_bar.dart';
import 'package:all_flutter0709/features/topic/data/models/topic_submit_media_model.dart';
import 'package:all_flutter0709/features/topic/presentation/helpers/topic_media_pick_helper.dart';
import 'package:all_flutter0709/features/topic/presentation/helpers/topic_mention_helper.dart';
import 'package:all_flutter0709/features/topic/presentation/topic_publish_controller.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_submit_local_preview_page.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_submit_media_grid.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_submit_toolbar.dart';
import 'package:all_flutter0709/features/user/data/models/user_base_model.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:chat_bottom_container/chat_bottom_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 发布图文 / 视频动态页，对齐 Android `TopicSubmitActivity`。
class TopicSubmitPage extends ConsumerStatefulWidget {
  const TopicSubmitPage({super.key});

  @override
  ConsumerState<TopicSubmitPage> createState() => _TopicSubmitPageState();
}

class _TopicSubmitPageState extends ConsumerState<TopicSubmitPage>
    with TickerProviderStateMixin {
  final TopicMentionEditingController _textController =
      TopicMentionEditingController();
  final FocusNode _focusNode = FocusNode();
  final TopicMediaPickHelper _mediaPickHelper = const TopicMediaPickHelper();
  final List<TopicSubmitMediaModel> _mediaList = <TopicSubmitMediaModel>[];

  late final AnimationController _shakeController;
  late final ChatPanelHelper _panelHelper;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _panelHelper = ChatPanelHelper(
      inputFocusNode: _focusNode,
      onUpdate: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
    _textController.setOnAtTyped(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_openUserSelect(byInput: true));
      });
    });
    _textController.addListener(_onTextOrSelectionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        _panelHelper.updatePanelType(ChatPanelType.keyboard);
      });
    });
  }

  @override
  void dispose() {
    _textController
      ..removeListener(_onTextOrSelectionChanged)
      ..dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onTextOrSelectionChanged() {
    _textController.handleTextChanged();
    _textController.snapSelection();
  }

  Future<void> _openUserSelect({required bool byInput}) async {
    _panelHelper.hidePanel();
    final userModel = await context.push<UserBaseModel>(
      '${AppRoutes.topic}/${AppRoutes.topicUserSelect}',
      extra: byInput,
    );
    if (!mounted || userModel == null) {
      return;
    }
    _textController.insertUser(userModel: userModel, byInput: byInput);
    setState(() {});
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _panelHelper.updatePanelType(ChatPanelType.keyboard);
    });
  }

  void _toggleEmoji() {
    _panelHelper.handleEmojiBtnClick();
  }

  void _insertEmoji(String emoji) {
    _textController.insertPlainText(emoji);
    setState(() {});
  }

  Future<void> _onAddMedia() async {
    _panelHelper.hidePanel();
    final canPickImage = _mediaPickHelper.remainImageCount(_mediaList) > 0;
    final canPickVideo = _mediaList.isEmpty;
    final action = await showModalBottomSheet<TopicMediaPickAction>(
      context: context,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return ColoredBox(
          color: Colors.white,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canPickImage)
                  ListTile(
                    title: const Center(child: Text('从相册选择图片')),
                    onTap: () => Navigator.pop(
                      sheetContext,
                      TopicMediaPickAction.pickImages,
                    ),
                  ),
                if (canPickVideo)
                  ListTile(
                    title: const Center(child: Text('从相册选择视频')),
                    onTap: () => Navigator.pop(
                      sheetContext,
                      TopicMediaPickAction.pickVideo,
                    ),
                  ),
                const Divider(height: 1),
                ListTile(
                  title: const Center(child: Text('取消')),
                  onTap: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || action == null) {
      return;
    }
    await _handleMediaAction(action);
  }

  Future<void> _handleMediaAction(TopicMediaPickAction action) async {
    switch (action) {
      case TopicMediaPickAction.pickImages:
        final pickedList = await _mediaPickHelper.pickImages(
          context: context,
          remainCount: _mediaPickHelper.remainImageCount(_mediaList),
        );
        if (pickedList.isNotEmpty) {
          setState(() => _mediaList.addAll(pickedList));
        }
      case TopicMediaPickAction.pickVideo:
        final mediaModel = await _mediaPickHelper.pickVideo(context: context);
        if (mediaModel != null) {
          setState(() {
            _mediaList
              ..clear()
              ..add(mediaModel);
          });
        }
    }
  }

  void _onSubmit() {
    if (!context.ensureLoggedIn()) {
      return;
    }
    final content = _textController.text.trim();
    if (content.isEmpty && _mediaList.isEmpty) {
      _shakeController.forward(from: 0);
      return;
    }
    ref
        .read(topicPublishControllerProvider)
        .publish(
          content: content,
          atUserIds: _textController.findAtUserIds(),
          mediaList: List<TopicSubmitMediaModel>.from(_mediaList),
        );
    _panelHelper.hidePanel();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bodyBackground,
      resizeToAvoidBottomInset: false,
      appBar: CommonAppBar(
        title: '发布动态',
        onLeadingPressed: () {
          _panelHelper.hidePanel();
          context.pop();
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                ColoredBox(
                  color: Colors.white,
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _shakeController,
                        builder: (context, child) {
                          final dx =
                              math.sin(_shakeController.value * math.pi * 8) *
                              8 *
                              (1 - _shakeController.value);
                          return Transform.translate(
                            offset: Offset(dx, 0),
                            child: child,
                          );
                        },
                        child: Listener(
                          onPointerUp: (_) =>
                              _panelHelper.handleInputViewOnPointerUp(),
                          child: TextField(
                            controller: _textController,
                            focusNode: _focusNode,
                            readOnly: _panelHelper.readOnly,
                            showCursor: true,
                            maxLines: null,
                            minLines: 6,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF5B5B5B),
                            ),
                            decoration: const InputDecoration(
                              hintText: '输入动态内容',
                              hintStyle: TextStyle(color: Color(0xFFB0B0B0)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.fromLTRB(8, 14, 8, 14),
                            ),
                          ),
                        ),
                      ),
                      TopicSubmitToolbar(
                        onAtTap: () =>
                            unawaited(_openUserSelect(byInput: false)),
                        onEmojiTap: _toggleEmoji,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 0.5),
                const SizedBox(height: 12),
                const Divider(height: 0.5),
                ColoredBox(
                  color: Colors.white,
                  child: TopicSubmitMediaGrid(
                    mediaList: _mediaList,
                    canAddMore: _mediaPickHelper.canAddMore(_mediaList),
                    onAddTap: () => unawaited(_onAddMedia()),
                    onItemTap: (index) {
                      final mediaModel = _mediaList[index];
                      unawaited(
                        TopicSubmitLocalPreviewPage.open(
                          context: context,
                          file: mediaModel.file,
                          isVideo: mediaModel.isVideo,
                        ),
                      );
                    },
                    onDeleteTap: (index) {
                      setState(() => _mediaList.removeAt(index));
                    },
                  ),
                ),
                const Divider(height: 0.5),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 30, 40, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _onSubmit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.link,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text('提交'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ChatBottomPanelContainer<ChatPanelType>(
            controller: _panelHelper.controller,
            inputFocusNode: _focusNode,
            panelBgColor: QInputBarColors.extendBackground,
            onPanelTypeChange: _panelHelper.onPanelTypeChange,
            otherPanelWidget: (type) {
              if (type != ChatPanelType.emoji) {
                return const SizedBox.shrink();
              }
              final keyboardHeight = _panelHelper.controller.keyboardHeight;
              return ChatEmojiPanel(
                height: keyboardHeight > 0 ? keyboardHeight : 280,
                onEmojiTap: _insertEmoji,
              );
            },
          ),
        ],
      ),
    );
  }
}
