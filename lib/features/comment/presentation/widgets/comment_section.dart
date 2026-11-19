import 'dart:async';
import 'dart:io';

import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/app/theme/app_palette.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/core/vip/vip_topic_guard.dart';
import 'package:all_flutter0709/features/conversation/presentation/helpers/vip_chat_guard.dart';
import 'package:all_flutter0709/core/emoji/qq_emoji_catalog.dart';
import 'package:all_flutter0709/core/emoji/qq_emoji_span.dart';
import 'package:all_flutter0709/features/comment/data/comment_repository.dart';
import 'package:all_flutter0709/features/comment/data/models/comment_display_model.dart';
import 'package:all_flutter0709/features/comment/data/models/comment_model.dart';
import 'package:all_flutter0709/features/comment/presentation/helpers/comment_list_local_helper.dart';
import 'package:all_flutter0709/features/comment/presentation/helpers/comment_long_press_menu.dart';
import 'package:all_flutter0709/features/comment/presentation/helpers/comment_send_helper.dart';
import 'package:all_flutter0709/features/comment/presentation/helpers/comment_audio_upload.dart';
import 'package:all_flutter0709/features/comment/presentation/helpers/comment_image_upload.dart';
import 'package:all_flutter0709/features/comment/presentation/helpers/comment_voice_record_helper.dart';
import 'package:all_flutter0709/features/comment/presentation/widgets/comment_bottom_input_bar.dart';
import 'package:all_flutter0709/features/comment/presentation/widgets/comment_item.dart';
import 'package:all_flutter0709/features/comment/presentation/widgets/comment_item_single_tips.dart';
import 'package:all_flutter0709/features/common/widget/common_state_placeholder.dart';
import 'package:all_flutter0709/features/common/helpers/album_image_pick_helper.dart';
import 'package:all_flutter0709/features/conversation/presentation/helpers/chat_panel_helper.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_emoji_panel.dart';
import 'package:all_flutter0709/features/conversation/presentation/widgets/chat_input_bar.dart';
import 'package:all_flutter0709/features/topic/data/topic_audio_file_store.dart';
import 'package:all_flutter0709/features/topic/presentation/helpers/topic_mention_helper.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_audio_list_scroll_notify.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_submit_local_preview_page.dart';
import 'package:all_flutter0709/features/user/data/models/user_base_model.dart';
import 'package:all_flutter0709/features/user/presentation/helpers/user_detail_navigation.dart';
import 'package:all_flutter0709/features/user/presentation/warning_report_page.dart';
import 'package:chat_bottom_container/chat_bottom_container.dart';
import 'package:all_flutter0709/shared/widgets/app_classic_header.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';

class CommentSection extends ConsumerStatefulWidget {
  const CommentSection({
    required this.targetId,
    required this.targetType,
    required this.header,
    required this.initialCommentCount,
    required this.authorUserId,
    super.key,
    this.onCommentCountChanged,
    this.listPadding = const EdgeInsets.fromLTRB(12, 12, 12, 24),
    this.enablePullRefresh = true,
  });

  final String targetId;
  final CommentTargetType targetType;
  final Widget header;
  final int initialCommentCount;
  final String authorUserId;
  final ValueChanged<int>? onCommentCountChanged;
  final EdgeInsetsGeometry listPadding;
  final bool enablePullRefresh;

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final CommentRepository _repository = const CommentRepository();
  final CommentSendHelper _sendHelper = const CommentSendHelper();
  final CommentListLocalHelper _listLocalHelper =
      const CommentListLocalHelper();
  final List<CommentDisplayModel> _items = <CommentDisplayModel>[];
  final Set<String> _likingCommentIds = <String>{};
  final TopicMentionEditingController _inputController =
      TopicMentionEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  late final ChatPanelHelper _panelHelper;
  late final QqEmojiSpanBuilder _emojiSpanBuilder;

  CommentReplyTarget? _replyTarget;
  late final CommentVoiceRecordHelper _voiceRecordHelper;
  bool _isVoiceMode = false;
  File? _pendingAudioFile;
  int _pendingAudioSeconds = 0;
  File? _pendingImageFile;
  int _nextPage = 1;
  int _commentCount = 0;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _commentCount = widget.initialCommentCount;
    _panelHelper = ChatPanelHelper(
      inputFocusNode: _inputFocusNode,
      onUpdate: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
    _emojiSpanBuilder = QqEmojiSpanBuilder(
      mentionRanges: () => [
        for (final rangeModel in _inputController.mentionList)
          (from: rangeModel.from, to: rangeModel.to),
      ],
    );
    _voiceRecordHelper = CommentVoiceRecordHelper(
      onUpdate: () {
        if (mounted) {
          setState(() {});
        }
      },
      onRecorded: (file, seconds) {
        if (!mounted) {
          unawaited(_deleteLocalAudio(file));
          return;
        }
        final previous = _pendingAudioFile;
        if (previous != null && previous.path != file.path) {
          unawaited(_deleteLocalAudio(previous));
        }
        setState(() {
          _pendingAudioFile = file;
          _pendingAudioSeconds = seconds;
          _isVoiceMode = false;
        });
      },
      onTip: _showSnack,
      onHidePanel: _panelHelper.hidePanel,
    );
    _inputController
      ..setOnAtTyped(() => _openUserSelect(byInput: true))
      ..addListener(_onInputChanged);
    unawaited(_refreshComments());
  }

  @override
  void didUpdateWidget(covariant CommentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetId != widget.targetId ||
        oldWidget.targetType != widget.targetType) {
      final pendingAudio = _pendingAudioFile;
      if (pendingAudio != null) {
        unawaited(_deleteLocalAudio(pendingAudio));
      }
      _replyTarget = null;
      _pendingAudioFile = null;
      _pendingAudioSeconds = 0;
      _pendingImageFile = null;
      _isVoiceMode = false;
      _items.clear();
      _nextPage = 1;
      _commentCount = widget.initialCommentCount;
      _hasMore = true;
      _isLoading = true;
      _errorText = null;
      unawaited(_refreshComments());
      return;
    }

    if (_items.isEmpty && widget.initialCommentCount != _commentCount) {
      _commentCount = widget.initialCommentCount;
    }
  }

  @override
  void dispose() {
    unawaited(_voiceRecordHelper.dispose());
    final pendingAudio = _pendingAudioFile;
    if (pendingAudio != null) {
      unawaited(_deleteLocalAudio(pendingAudio));
    }
    _inputController
      ..removeListener(_onInputChanged)
      ..dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshComments() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final result = await _repository.getCommentList(
        targetId: widget.targetId,
        type: widget.targetType,
        page: 1,
      );
      if (!mounted) return;

      setState(() {
        _items
          ..clear()
          ..addAll(_flattenPage(result.items));
        _nextPage = 2;
        _hasMore = result.hasMore;
        _isLoading = false;
        _errorText = null;
        _syncCommentCount(result.total);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadMoreComments() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await _repository.getCommentList(
        targetId: widget.targetId,
        type: widget.targetType,
        page: _nextPage,
      );
      if (!mounted) return;

      setState(() {
        _items.addAll(_flattenPage(result.items));
        _nextPage++;
        _hasMore = result.hasMore;
        _isLoadingMore = false;
        _syncCommentCount(result.total);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
      _showSnack(error.toString());
    }
  }

  Future<void> _loadMoreReplies(CommentDisplayModel actionItem) async {
    final loadingIndex = _items.indexOf(actionItem);
    if (loadingIndex == -1) return;

    setState(() {
      _items[loadingIndex] = actionItem.copyWith(
        displayType: CommentDisplayType.loadingMoreComment,
      );
    });

    try {
      final result = await _repository.getChildCommentList(
        parentCid: actionItem.parentCid,
        startCid: actionItem.startCid,
      );
      if (!mounted) return;

      setState(() {
        final currentIndex = _items.indexWhere(
          (item) =>
              item.isAction &&
              item.parentCid == actionItem.parentCid &&
              item.displayType != CommentDisplayType.packUpComment,
        );
        if (currentIndex == -1) return;

        _items.removeAt(currentIndex);
        final children = result.items
            .map(
              (comment) => CommentDisplayModel.child(
                comment,
                displayType: CommentDisplayType.childCommentMiddle,
              ),
            )
            .toList(growable: false);
        _items.insertAll(currentIndex, children);

        if (result.items.isNotEmpty) {
          final lastChild = result.items.last;
          _items.insert(
            currentIndex + children.length,
            CommentDisplayModel.action(
              parentCid: actionItem.parentCid,
              startCid: lastChild.cid,
              totalChildCount: actionItem.totalChildCount,
              displayType: result.hasMore
                  ? CommentDisplayType.showMoreComment
                  : CommentDisplayType.packUpComment,
            ),
          );
        }
      });
    } catch (error) {
      if (!mounted) return;
      final currentIndex = _items.indexWhere(
        (item) =>
            item.isAction &&
            item.parentCid == actionItem.parentCid &&
            item.displayType == CommentDisplayType.loadingMoreComment,
      );
      if (currentIndex != -1) {
        setState(() {
          _items[currentIndex] = _items[currentIndex].copyWith(
            displayType: CommentDisplayType.showMoreComment,
          );
        });
      }
      _showSnack(error.toString());
    }
  }

  void _onInputChanged() {
    _inputController.handleTextChanged();
    _inputController.snapSelection();
  }

  Future<void> _openUserSelect({required bool byInput}) async {
    if (!context.ensureLoggedIn()) return;
    if (_voiceRecordHelper.isRecording) return;
    if (_isVoiceMode) {
      setState(() {
        _isVoiceMode = false;
      });
    }
    _panelHelper.hidePanel();
    final userModel = await context.push<UserBaseModel>(
      '${AppRoutes.topic}/${AppRoutes.topicUserSelect}',
    );
    if (!mounted || userModel == null) return;
    _inputController.insertUser(userModel: userModel, byInput: byInput);
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _panelHelper.updatePanelType(ChatPanelType.keyboard);
    });
  }

  void _insertEmoji(String emoji) {
    _inputController.insertPlainText(emoji);
  }

  void _deleteEmoji() {
    _inputController.value = QqEmojiEditing.deleteBackward(
      _inputController.value,
    );
  }

  bool _hidePanelOnListDrag(ScrollNotification notification) {
    if (notification.depth != 0 ||
        notification is! ScrollStartNotification ||
        notification.dragDetails == null) {
      return false;
    }
    _panelHelper.hidePanel();
    return false;
  }

  Future<void> _pickCommentImage() async {
    if (!context.ensureLoggedIn() || _voiceRecordHelper.isRecording) {
      return;
    }
    if (_isVoiceMode) {
      setState(() {
        _isVoiceMode = false;
      });
    }
    _panelHelper.hidePanel();
    final file = await const AlbumImagePickHelper().pickImage(context: context);
    if (!mounted || file == null) {
      return;
    }
    setState(() {
      _pendingImageFile = file;
    });
  }

  void _previewPendingImage() {
    final file = _pendingImageFile;
    if (file == null) {
      return;
    }
    unawaited(TopicSubmitLocalPreviewPage.open(context: context, file: file));
  }

  Future<void> _sendComment() async {
    final account = context.currentAccount;
    if (account == null) {
      context.ensureLoggedIn();
      return;
    }

    if (topicCommentRequiresVip(account: account)) {
      await showVipRequiredDialog(context);
      return;
    }

    final content = _inputController.text.trim();
    final pendingAudio = _pendingAudioFile;
    final pendingImage = _pendingImageFile;
    if (content.isEmpty && pendingAudio == null && pendingImage == null) {
      _showSnack('请输入评论、选择图片或录制语音');
      return;
    }
    final atUserIds = _inputController.findAtUserIds();
    final audioSeconds = _pendingAudioSeconds;

    final localComment = _sendHelper.buildLocalComment(
      account: account,
      targetId: widget.targetId,
      content: content,
      replyTarget: _replyTarget,
      localAudioFile: pendingAudio,
      audioDurationSeconds: audioSeconds,
      localImageFile: pendingImage,
    );

    _panelHelper.hidePanel();
    setState(() {
      _listLocalHelper.insertOptimisticComment(_items, localComment);
      _replyTarget = null;
      _inputController.clearContent();
      _pendingAudioFile = null;
      _pendingAudioSeconds = 0;
      _pendingImageFile = null;
      _syncCommentCount(_commentCount + 1);
    });
    if (!localComment.isRoot) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            (_scrollController.offset - 80).clamp(
              0,
              _scrollController.position.maxScrollExtent,
            ),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
          );
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }

    try {
      var audioKey = '';
      if (pendingAudio != null) {
        audioKey = await CommentAudioUpload.upload(pendingAudio);
      }
      CommentImageUploadResult? imageResult;
      if (pendingImage != null) {
        imageResult = await CommentImageUpload.upload(pendingImage);
      }
      final result = await _sendHelper.submit(
        targetId: widget.targetId,
        type: widget.targetType,
        localComment: localComment,
        atUserIds: atUserIds,
        audioFileName: audioKey,
        audioDurationSeconds: audioSeconds,
        photoArrayJson: imageResult?.photoArrayJson ?? '',
      );
      File? cachedAudio = pendingAudio;
      if (pendingAudio != null && audioKey.isNotEmpty) {
        try {
          cachedAudio = await TopicAudioFileStore.persistLocalFile(
            source: pendingAudio,
            filename: audioKey,
          );
        } catch (_) {
          // 缓存失败不影响已经提交成功的评论，当前会话继续使用原临时文件。
        }
      }
      if (!mounted) return;

      setState(() {
        _listLocalHelper.updateCommentByTempId(
          _items,
          localComment.tempId,
          (comment) => comment.copyWith(
            cid: result.cid.isNotEmpty ? result.cid : comment.cid,
            sendState: CommentSendState.normal,
            audioFileName: audioKey,
            localAudioFile: cachedAudio,
            pictures: imageResult == null
                ? comment.pictures
                : [imageResult.picture],
          ),
        );
      });
    } catch (error) {
      if (pendingAudio != null) {
        await _deleteLocalAudio(pendingAudio);
      }
      if (!mounted) return;
      setState(() {
        _listLocalHelper.removeOptimisticComment(_items, localComment);
        _syncCommentCount(_commentCount - 1);
      });
      _showSnack(error.toString());
    }
  }

  Future<void> _toggleCommentLike(CommentModel comment) async {
    if (comment.cid.isEmpty) return;
    if (!context.ensureLoggedIn()) return;
    if (_likingCommentIds.contains(comment.effectiveId)) return;

    final nextIsLiked = !comment.isLiked;
    final nextLikeCount = nextIsLiked
        ? comment.likeCount + 1
        : (comment.likeCount > 0 ? comment.likeCount - 1 : 0);
    final effectiveId = comment.effectiveId;

    _likingCommentIds.add(effectiveId);
    setState(() {
      _listLocalHelper.updateCommentByEffectiveId(
        _items,
        effectiveId,
        (current) =>
            current.copyWith(isLiked: nextIsLiked, likeCount: nextLikeCount),
      );
    });

    try {
      await _repository.likeComment(
        cid: comment.cid,
        isLiked: comment.isLiked,
        likeCount: comment.likeCount,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _listLocalHelper.updateCommentByEffectiveId(
          _items,
          effectiveId,
          (_) => comment,
        );
      });
      _showSnack(error.toString());
    } finally {
      _likingCommentIds.remove(effectiveId);
    }
  }

  Future<void> _handleCommentLongPress(
    BuildContext anchorContext,
    CommentModel commentModel,
  ) async {
    final currentUserId = context.currentUserId;
    final isCommentOwner =
        currentUserId.isNotEmpty && currentUserId == commentModel.userId;
    final isFeedAuthor =
        currentUserId.isNotEmpty && currentUserId == widget.authorUserId;
    final action = await CommentLongPressMenu.show(
      anchorContext: anchorContext,
      canDelete: isCommentOwner || isFeedAuthor,
    );
    if (!mounted || action == null) return;

    switch (action) {
      case CommentLongPressAction.copy:
        await Clipboard.setData(
          ClipboardData(text: commentModel.displayContent),
        );
        _showSnack('复制成功');
      case CommentLongPressAction.delete:
        await _deleteComment(commentModel);
      case CommentLongPressAction.report:
        openWarningReportPage(context);
      case CommentLongPressAction.reply:
        _handleCommentTap(commentModel);
    }
  }

  Future<void> _deleteComment(CommentModel commentModel) async {
    if (!context.ensureLoggedIn()) return;
    if (commentModel.cid.isEmpty) {
      _showSnack('评论发送中，请稍后再试');
      return;
    }

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) {
          return const PopScope(
            canPop: false,
            child: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );

    Object? error;
    var deletedCid = commentModel.cid;
    try {
      deletedCid = await _repository.deleteComment(cid: commentModel.cid);
    } catch (caught) {
      error = caught;
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
    if (!mounted) return;
    if (error != null) {
      _showSnack(error.toString());
      return;
    }

    setState(() {
      final removedCount = _listLocalHelper.removeDeletedComment(
        _items,
        deletedCid,
      );
      _syncCommentCount(_commentCount - removedCount);
      _replyTarget = null;
      _inputController.clearContent();
    });
    _panelHelper.hidePanel();
  }

  void _handleCommentTap(CommentModel comment) {
    final currentUserId = context.currentUserId;
    final isReplyToCurrentUser =
        currentUserId.isNotEmpty && currentUserId == comment.userId;
    final parentCid = comment.isRoot ? comment.effectiveId : comment.parentCid;

    final isRecording = _voiceRecordHelper.isRecording;
    setState(() {
      _replyTarget = CommentReplyTarget(
        parentCid: parentCid,
        toUserId: isReplyToCurrentUser ? '' : comment.userId,
        toUserName: isReplyToCurrentUser ? '' : comment.userName,
        toAvatar: isReplyToCurrentUser ? null : comment.avatar,
        hintText: '回复 @${comment.userName}',
      );
      if (!isRecording) {
        _isVoiceMode = false;
      }
    });

    if (!isRecording) {
      _panelHelper.updatePanelType(ChatPanelType.keyboard);
      // Android 收起键盘后可能仍保留输入框焦点，requestFocus 不会再次弹出；
      // 直接显示输入法，不再通过 scheduler 反复切换焦点。
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    }
  }

  List<CommentDisplayModel> _flattenPage(List<CommentModel> comments) {
    final result = <CommentDisplayModel>[];
    for (final root in comments) {
      final children = root.children;
      result.add(
        CommentDisplayModel.root(
          root,
          displayType: children.isEmpty
              ? CommentDisplayType.fatherCommentNoChild
              : CommentDisplayType.fatherCommentContainsChild,
        ),
      );
      for (var i = 0; i < children.length; i++) {
        final child = children[i];
        final isLastLoadedChild =
            children.length >= root.childCount && i == children.length - 1;
        result.add(
          CommentDisplayModel.child(
            child,
            displayType: isLastLoadedChild
                ? CommentDisplayType.childCommentLast
                : CommentDisplayType.childCommentMiddle,
          ),
        );
      }
      if (children.length < root.childCount && children.isNotEmpty) {
        result.add(
          CommentDisplayModel.action(
            parentCid: root.effectiveId,
            startCid: children.last.cid,
            totalChildCount: root.childCount,
            displayType: CommentDisplayType.showMoreComment,
          ),
        );
      }
    }
    return result;
  }

  void _syncCommentCount(int nextValue) {
    final resolved = nextValue < 0 ? 0 : nextValue;
    if (_commentCount == resolved) return;
    _commentCount = resolved;
    widget.onCommentCountChanged?.call(_commentCount);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    AppToast.show(context, message.replaceFirst('Exception: ', ''));
  }

  void _toggleVoiceMode() {
    if (!context.ensureLoggedIn()) {
      return;
    }
    if (_voiceRecordHelper.isRecording) {
      return;
    }
    setState(() {
      _isVoiceMode = !_isVoiceMode;
      if (_isVoiceMode) {
        _panelHelper.hidePanel();
      } else {
        _panelHelper.updatePanelType(ChatPanelType.keyboard);
      }
    });
  }

  void _toggleEmoji() {
    if (!context.ensureLoggedIn() || _voiceRecordHelper.isRecording) {
      return;
    }
    if (_isVoiceMode) {
      setState(() {
        _isVoiceMode = false;
      });
    }
    _panelHelper.handleEmojiBtnClick();
  }

  Future<void> _deleteLocalAudio(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: _hidePanelOnListDrag,
            child: TopicAudioListScrollNotify(
              child: EasyRefresh(
                header: appClassicHeader(context),
                footer: const ClassicFooter(showMessage: false),
                onRefresh: widget.enablePullRefresh ? _refreshComments : null,
                onLoad: _hasMore && !_isLoading ? _loadMoreComments : null,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: widget.listPadding,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: _buildVisibleItemCount(),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildHeaderAndCommentTitle();
                    }

                    if (_isLoading && _items.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (_errorText != null && _items.isEmpty) {
                      return CommonStatePlaceholder(
                        icon: Icons.wifi_off_outlined,
                        text: _errorText!,
                        actionText: '重试',
                        onTap: () {
                          unawaited(_refreshComments());
                        },
                      );
                    }

                    if (_items.isEmpty) {
                      return const CommonStatePlaceholder(
                        icon: Icons.mode_comment_outlined,
                        text: '还没有评论，来抢沙发吧',
                      );
                    }

                    final item = _items[index - 1];
                    if (item.isAction) {
                      return CommentItemSingleTips(
                        item: item,
                        onTap: () {
                          unawaited(_loadMoreReplies(item));
                        },
                      );
                    }
                    return CommentItem(
                      key: ValueKey('comment-${item.comment!.effectiveId}'),
                      comment: item.comment!,
                      isChild: item.isChild,
                      authorUserId: widget.authorUserId,
                      displayType: item.displayType!,
                      onTap: () => _handleCommentTap(item.comment!),
                      onLongPress: (anchorContext) {
                        unawaited(
                          _handleCommentLongPress(anchorContext, item.comment!),
                        );
                      },
                      onLikeTap: () => _toggleCommentLike(item.comment!),
                      onAvatarTap: () {
                        final comment = item.comment!;
                        openUserDetailPage(
                          context,
                          userId: comment.userId,
                          name: comment.userName,
                          avatar: comment.avatar,
                          userType: comment.userType,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        CommentBottomInputBar(
          controller: _inputController,
          focusNode: _inputFocusNode,
          emojiSpanBuilder: _emojiSpanBuilder,
          readOnly: _panelHelper.readOnly,
          isEmojiPanel: _panelHelper.currentPanelType == ChatPanelType.emoji,
          isVoiceMode: _isVoiceMode,
          onToggleVoiceMode: _toggleVoiceMode,
          isRecording: _voiceRecordHelper.isRecording,
          willCancelRecording: _voiceRecordHelper.willCancel,
          onVoicePointerDown: _voiceRecordHelper.handlePointerDown,
          onVoicePointerMove: _voiceRecordHelper.handlePointerMove,
          onVoicePointerUp: _voiceRecordHelper.handlePointerUp,
          onVoicePointerCancel: _voiceRecordHelper.handlePointerCancel,
          pendingAudioFile: _pendingAudioFile,
          pendingAudioSeconds: _pendingAudioSeconds,
          onDeletePendingAudio: () {
            final pendingAudio = _pendingAudioFile;
            if (pendingAudio != null) {
              unawaited(_deleteLocalAudio(pendingAudio));
            }
            setState(() {
              _pendingAudioFile = null;
              _pendingAudioSeconds = 0;
            });
          },
          pendingImageFile: _pendingImageFile,
          onImageTap: () => unawaited(_pickCommentImage()),
          onPendingImageTap: _previewPendingImage,
          onDeletePendingImage: () {
            setState(() {
              _pendingImageFile = null;
            });
          },
          replyHintText: _replyTarget?.hintText,
          onCancelReply: () {
            setState(() {
              _replyTarget = null;
            });
          },
          onSend: _sendComment,
          onToggleEmoji: _toggleEmoji,
          onInputPointerUp: _panelHelper.handleInputViewOnPointerUp,
        ),
        ChatBottomPanelContainer<ChatPanelType>(
          controller: _panelHelper.controller,
          inputFocusNode: _inputFocusNode,
          panelBgColor: QInputBarColors.extendBackground(context.palette),
          onPanelTypeChange: _panelHelper.onPanelTypeChange,
          otherPanelWidget: (type) {
            if (type != ChatPanelType.emoji) {
              return const SizedBox.shrink();
            }
            final keyboardHeight = _panelHelper.controller.keyboardHeight;
            return ChatEmojiPanel(
              height: keyboardHeight > 0 ? keyboardHeight : 280,
              onEmojiTap: _insertEmoji,
              onDelete: _deleteEmoji,
            );
          },
        ),
      ],
    );
    final overlay = _voiceRecordHelper.buildOverlay();
    return Stack(children: [body, ?overlay]);
  }

  int _buildVisibleItemCount() {
    if (_isLoading && _items.isEmpty) return 2;
    if (_errorText != null && _items.isEmpty) return 2;
    if (_items.isEmpty) return 2;
    return _items.length + 1;
  }

  Widget _buildHeaderAndCommentTitle() {
    final hasComments = _items.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.header,
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: context.palette.card,
            borderRadius: hasComments
                ? const BorderRadius.vertical(top: Radius.circular(16))
                : BorderRadius.circular(16),
          ),
          child: Text(
            '全部评论 ${_commentCount > 0 ? _commentCount : ''}'.trim(),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: context.palette.titleText,
            ),
          ),
        ),
      ],
    );
  }
}
