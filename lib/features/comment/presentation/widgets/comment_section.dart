import 'dart:async';

import 'package:all_flutter0709/core/account/account.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:all_flutter0709/features/comment/data/comment_repository.dart';
import 'package:all_flutter0709/features/comment/data/models/comment_display_model.dart';
import 'package:all_flutter0709/features/comment/data/models/comment_model.dart';
import 'package:all_flutter0709/features/comment/presentation/widgets/comment_bottom_input_bar.dart';
import 'package:all_flutter0709/features/comment/presentation/widgets/comment_item.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommentSection extends ConsumerStatefulWidget {
  const CommentSection({
    required this.targetId,
    required this.targetType,
    required this.header,
    required this.initialCommentCount,
    required this.authorUserId,
    super.key,
    this.onCommentCountChanged,
  });

  final String targetId;
  final CommentTargetType targetType;
  final Widget header;
  final int initialCommentCount;
  final String authorUserId;
  final ValueChanged<int>? onCommentCountChanged;

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final CommentRepository _repository = const CommentRepository();
  final List<CommentDisplayModel> _items = <CommentDisplayModel>[];
  final Set<String> _likingCommentIds = <String>{};
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  _CommentReplyTarget? _replyTarget;
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
    _inputController.addListener(_handleComposerChanged);
    unawaited(_refreshComments());
  }

  @override
  void didUpdateWidget(covariant CommentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetId != widget.targetId ||
        oldWidget.targetType != widget.targetType) {
      _replyTarget = null;
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
    _inputController
      ..removeListener(_handleComposerChanged)
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

  Future<void> _sendComment() async {
    final account = context.currentAccount;
    if (account == null) {
      context.ensureLoggedIn();
      return;
    }

    final content = _inputController.text.trim();
    if (content.isEmpty) {
      _showSnack('请输入评论内容');
      return;
    }

    final localComment = _buildLocalComment(account, content, _replyTarget);

    _inputFocusNode.unfocus();
    setState(() {
      _insertOptimisticComment(localComment);
      _replyTarget = null;
      _inputController.clear();
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
      final result = await _repository.submitComment(
        targetId: widget.targetId,
        type: widget.targetType,
        content: localComment.content,
        tempId: localComment.tempId,
        parentCid: localComment.isRoot ? null : localComment.parentCid,
        toUserId: localComment.toUserId,
        toUserName: localComment.toUserName,
      );
      if (!mounted) return;

      setState(() {
        _updateCommentByTempId(
          localComment.tempId,
          (comment) => comment.copyWith(
            cid: result.cid.isNotEmpty ? result.cid : comment.cid,
            sendState: CommentSendState.normal,
          ),
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _removeOptimisticComment(localComment);
        _syncCommentCount(_commentCount - 1);
      });
      _showSnack(error.toString());
    }
  }

  void _insertOptimisticComment(CommentModel comment) {
    if (comment.isRoot) {
      _items.insert(
        0,
        CommentDisplayModel.root(
          comment,
          displayType: CommentDisplayType.fatherCommentNoChild,
        ),
      );
      return;
    }

    final rootIndex = _items.indexWhere(
      (item) => item.isComment && item.comment!.effectiveId == comment.parentCid,
    );
    if (rootIndex == -1) {
      _items.insert(
        0,
        CommentDisplayModel.root(
          comment,
          displayType: CommentDisplayType.fatherCommentNoChild,
        ),
      );
      return;
    }

    final rootItem = _items[rootIndex];
    _items[rootIndex] = rootItem.copyWith(
      comment: rootItem.comment!.copyWith(
        childCount: rootItem.comment!.childCount + 1,
      ),
      displayType: CommentDisplayType.fatherCommentContainsChild,
    );
    _items.insert(
      rootIndex + 1,
      CommentDisplayModel.child(
        comment,
        displayType: rootItem.comment!.childCount == 0
            ? CommentDisplayType.childCommentLast
            : CommentDisplayType.childCommentMiddle,
      ),
    );

    final actionIndex = _items.indexWhere(
      (item) => item.isAction && item.parentCid == comment.parentCid,
    );
    if (actionIndex != -1) {
      final actionItem = _items[actionIndex];
      _items[actionIndex] = actionItem.copyWith(
        totalChildCount: actionItem.totalChildCount + 1,
      );
    }
  }

  CommentModel _buildLocalComment(
    AccountModel account,
    String content,
    _CommentReplyTarget? replyTarget,
  ) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final tempId = DateTime.now().microsecondsSinceEpoch.toString();

    return CommentModel(
      cid: '',
      tempId: tempId,
      targetId: widget.targetId,
      parentCid: replyTarget?.parentCid ?? '0',
      userId: account.userId,
      userName: account.name,
      avatar: ValueUtil.getQiniuUrlByFileName(
        account.avatar,
        thumbnail: true,
      ),
      toUserId: replyTarget?.toUserId ?? '',
      toUserName: replyTarget?.toUserName ?? '',
      toAvatar: replyTarget?.toAvatar,
      content: content,
      likeCount: 0,
      childCount: 0,
      createTime: now,
      isLiked: false,
      pictures: const [],
      children: const [],
      sendState: CommentSendState.sending,
    );
  }

  void _updateCommentByTempId(
    String tempId,
    CommentModel Function(CommentModel comment) transform,
  ) {
    final index = _items.indexWhere(
      (item) => item.isComment && item.comment!.tempId == tempId,
    );
    if (index == -1) return;
    _items[index] = _items[index].copyWith(comment: transform(_items[index].comment!));
  }

  void _removeOptimisticComment(CommentModel comment) {
    final index = _items.indexWhere(
      (item) => item.isComment && item.comment!.tempId == comment.tempId,
    );
    if (index == -1) return;

    if (comment.isRoot) {
      _items.removeAt(index);
      return;
    }

    final rootIndex = _items.indexWhere(
      (item) => item.isComment && item.comment!.effectiveId == comment.parentCid,
    );
    _items.removeAt(index);

    if (rootIndex == -1) return;

    final rootItem = _items[rootIndex];
    final nextChildCount = rootItem.comment!.childCount > 0
        ? rootItem.comment!.childCount - 1
        : 0;
    _items[rootIndex] = rootItem.copyWith(
      comment: rootItem.comment!.copyWith(childCount: nextChildCount),
      displayType: nextChildCount == 0
          ? CommentDisplayType.fatherCommentNoChild
          : CommentDisplayType.fatherCommentContainsChild,
    );

    final actionIndex = _items.indexWhere(
      (item) => item.isAction && item.parentCid == comment.parentCid,
    );
    if (actionIndex != -1) {
      final actionItem = _items[actionIndex];
      final nextTotalChildCount = actionItem.totalChildCount > 0
          ? actionItem.totalChildCount - 1
          : 0;
      _items[actionIndex] = actionItem.copyWith(
        totalChildCount: nextTotalChildCount,
      );
    }
  }

  void _updateCommentByEffectiveId(
    String effectiveId,
    CommentModel Function(CommentModel comment) transform,
  ) {
    final index = _items.indexWhere(
      (item) => item.isComment && item.comment!.effectiveId == effectiveId,
    );
    if (index == -1) return;
    _items[index] = _items[index].copyWith(comment: transform(_items[index].comment!));
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
      _updateCommentByEffectiveId(
        effectiveId,
        (current) => current.copyWith(
          isLiked: nextIsLiked,
          likeCount: nextLikeCount,
        ),
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
        _updateCommentByEffectiveId(effectiveId, (_) => comment);
      });
      _showSnack(error.toString());
    } finally {
      _likingCommentIds.remove(effectiveId);
    }
  }

  void _handleCommentTap(CommentModel comment) {
    final currentUserId = context.currentUserId;
    final isReplyToCurrentUser = currentUserId.isNotEmpty && currentUserId == comment.userId;
    final parentCid = comment.isRoot ? comment.effectiveId : comment.parentCid;

    setState(() {
      _replyTarget = _CommentReplyTarget(
        parentCid: parentCid,
        toUserId: isReplyToCurrentUser ? '' : comment.userId,
        toUserName: isReplyToCurrentUser ? '' : comment.userName,
        toAvatar: isReplyToCurrentUser ? null : comment.avatar,
        hintText: '回复 @${comment.userName}',
      );
    });

    _inputFocusNode.requestFocus();
  }

  void _handleComposerChanged() {
    if (mounted) {
      setState(() {});
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message.replaceFirst('Exception: ', ''))));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: EasyRefresh(
            header: const ClassicHeader(showMessage: false, showText: false),
            footer: const ClassicFooter(showMessage: false),
            onRefresh: _refreshComments,
            onLoad: _hasMore && !_isLoading ? _loadMoreComments : null,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: _buildVisibleItemCount(),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildHeader();
                }

                if (_isLoading && _items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (_errorText != null && _items.isEmpty) {
                  return _StateHint(
                    icon: Icons.wifi_off_outlined,
                    text: _errorText!,
                    actionText: '重试',
                    onTap: () {
                      unawaited(_refreshComments());
                    },
                  );
                }

                if (_items.isEmpty) {
                  return const _StateHint(
                    icon: Icons.mode_comment_outlined,
                    text: '还没有评论，来抢沙发吧',
                  );
                }

                final item = _items[index - 1];
                if (item.isAction) {
                  return _CommentActionTile(
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
                  onLikeTap: () => _toggleCommentLike(item.comment!),
                );
              },
            ),
          ),
        ),
        CommentBottomInputBar(
          controller: _inputController,
          focusNode: _inputFocusNode,
          replyHintText: _replyTarget?.hintText,
          onCancelReply: () {
            setState(() {
              _replyTarget = null;
            });
          },
          onSend: _sendComment,
        ),
      ],
    );
  }

  int _buildVisibleItemCount() {
    if (_isLoading && _items.isEmpty) return 2;
    if (_errorText != null && _items.isEmpty) return 2;
    if (_items.isEmpty) return 2;
    return _items.length + 1;
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.header,
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '全部评论 ${_commentCount > 0 ? _commentCount : ''}'.trim(),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF222222),
            ),
          ),
        ),
      ],
    );
  }
}

class _CommentActionTile extends StatelessWidget {
  const _CommentActionTile({
    required this.item,
    required this.onTap,
  });

  final CommentDisplayModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayType = item.displayType!;
    final label = switch (displayType) {
      CommentDisplayType.loadingMoreComment => '',
      CommentDisplayType.packUpComment => '已经是全部回复了',
      CommentDisplayType.showMoreComment => '加载全部${item.totalChildCount}条回复',
      _ => '',
    };

    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 20,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 0.6,
                          height: 23,
                          color: const Color(0xFFDCDCDC),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 23),
                      child: Container(
                        width: 20,
                        height: 0.6,
                        color: const Color(0xFFDCDCDC),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 2),
                  child: displayType == CommentDisplayType.loadingMoreComment
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : GestureDetector(
                          onTap: onTap,
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF133465),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
          if (showCommentSeparator(displayType))
            const Padding(
              padding: EdgeInsets.only(left: 61, top: 10),
              child: Divider(height: 0.6, thickness: 0.6),
            ),
        ],
      ),
    );
  }
}

class _StateHint extends StatelessWidget {
  const _StateHint({
    required this.icon,
    required this.text,
    this.actionText,
    this.onTap,
  });

  final IconData icon;
  final String text;
  final String? actionText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: const Color(0xFFB3B3B8)),
            const SizedBox(height: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF7B7B80),
              ),
            ),
            if (actionText != null && onTap != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onTap, child: Text(actionText!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommentReplyTarget {
  const _CommentReplyTarget({
    required this.parentCid,
    required this.toUserId,
    required this.toUserName,
    required this.toAvatar,
    required this.hintText,
  });

  final String parentCid;
  final String toUserId;
  final String toUserName;
  final String? toAvatar;
  final String hintText;
}
