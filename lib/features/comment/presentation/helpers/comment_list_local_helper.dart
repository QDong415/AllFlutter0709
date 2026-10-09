import 'package:all_flutter0709/features/comment/data/models/comment_display_model.dart';
import 'package:all_flutter0709/features/comment/data/models/comment_model.dart';

/// 评论列表的本地结构变更（乐观插入 / 回滚 / 按 id 更新），不发起网络请求。
class CommentListLocalHelper {
  const CommentListLocalHelper();

  void insertOptimisticComment(
    List<CommentDisplayModel> items,
    CommentModel comment,
  ) {
    if (comment.isRoot) {
      items.insert(
        0,
        CommentDisplayModel.root(
          comment,
          displayType: CommentDisplayType.fatherCommentNoChild,
        ),
      );
      return;
    }

    final rootIndex = items.indexWhere(
      (item) => item.isComment && item.comment!.effectiveId == comment.parentCid,
    );
    if (rootIndex == -1) {
      items.insert(
        0,
        CommentDisplayModel.root(
          comment,
          displayType: CommentDisplayType.fatherCommentNoChild,
        ),
      );
      return;
    }

    final rootItem = items[rootIndex];
    items[rootIndex] = rootItem.copyWith(
      comment: rootItem.comment!.copyWith(
        childCount: rootItem.comment!.childCount + 1,
      ),
      displayType: CommentDisplayType.fatherCommentContainsChild,
    );
    items.insert(
      rootIndex + 1,
      CommentDisplayModel.child(
        comment,
        displayType: rootItem.comment!.childCount == 0
            ? CommentDisplayType.childCommentLast
            : CommentDisplayType.childCommentMiddle,
      ),
    );

    final actionIndex = items.indexWhere(
      (item) => item.isAction && item.parentCid == comment.parentCid,
    );
    if (actionIndex != -1) {
      final actionItem = items[actionIndex];
      items[actionIndex] = actionItem.copyWith(
        totalChildCount: actionItem.totalChildCount + 1,
      );
    }
  }

  void removeOptimisticComment(
    List<CommentDisplayModel> items,
    CommentModel comment,
  ) {
    final index = items.indexWhere(
      (item) => item.isComment && item.comment!.tempId == comment.tempId,
    );
    if (index == -1) return;

    if (comment.isRoot) {
      items.removeAt(index);
      return;
    }

    final rootIndex = items.indexWhere(
      (item) => item.isComment && item.comment!.effectiveId == comment.parentCid,
    );
    items.removeAt(index);

    if (rootIndex == -1) return;

    final rootItem = items[rootIndex];
    final nextChildCount = rootItem.comment!.childCount > 0
        ? rootItem.comment!.childCount - 1
        : 0;
    items[rootIndex] = rootItem.copyWith(
      comment: rootItem.comment!.copyWith(childCount: nextChildCount),
      displayType: nextChildCount == 0
          ? CommentDisplayType.fatherCommentNoChild
          : CommentDisplayType.fatherCommentContainsChild,
    );

    final actionIndex = items.indexWhere(
      (item) => item.isAction && item.parentCid == comment.parentCid,
    );
    if (actionIndex != -1) {
      final actionItem = items[actionIndex];
      final nextTotalChildCount = actionItem.totalChildCount > 0
          ? actionItem.totalChildCount - 1
          : 0;
      items[actionIndex] = actionItem.copyWith(
        totalChildCount: nextTotalChildCount,
      );
    }
  }

  void updateCommentByTempId(
    List<CommentDisplayModel> items,
    String tempId,
    CommentModel Function(CommentModel comment) transform,
  ) {
    final index = items.indexWhere(
      (item) => item.isComment && item.comment!.tempId == tempId,
    );
    if (index == -1) return;
    items[index] = items[index].copyWith(
      comment: transform(items[index].comment!),
    );
  }

  /// 删除成功后从列表去掉这条评论。
  ///
  /// 删一级评论时，连同已加载的子回复和「查看更多」行一起去掉，返回值是
  /// 1 + 该评论的子回复总数，用来扣减动态评论数。删子回复时只去掉这一条，
  /// 并回写父评论的子回复数，返回 1。
  int removeDeletedComment(List<CommentDisplayModel> itemList, String cid) {
    final index = itemList.indexWhere(
      (item) => item.isComment && item.comment!.cid == cid,
    );
    if (index < 0) return 0;

    final commentModel = itemList[index].comment!;
    if (commentModel.isRoot) {
      final removedCount = 1 + commentModel.childCount;
      itemList.removeAt(index);
      while (index < itemList.length &&
          _belongsToParent(itemList[index], cid)) {
        itemList.removeAt(index);
      }
      return removedCount;
    }

    final parentCid = commentModel.parentCid;
    itemList.removeAt(index);
    _syncParentAfterChildRemoved(itemList, parentCid);
    return 1;
  }

  bool _belongsToParent(CommentDisplayModel item, String parentCid) {
    if (item.isComment) {
      return item.comment!.parentCid == parentCid;
    }
    return item.parentCid == parentCid;
  }

  void _syncParentAfterChildRemoved(
    List<CommentDisplayModel> itemList,
    String parentCid,
  ) {
    final rootIndex = itemList.indexWhere(
      (item) =>
          item.isComment &&
          !item.isChild &&
          item.comment!.effectiveId == parentCid,
    );
    if (rootIndex < 0) return;

    final rootItem = itemList[rootIndex];
    final nextChildCount = rootItem.comment!.childCount > 0
        ? rootItem.comment!.childCount - 1
        : 0;

    final childIndexList = <int>[];
    int? actionIndex;
    for (var cursor = rootIndex + 1; cursor < itemList.length; cursor++) {
      final item = itemList[cursor];
      if (item.isComment && !item.isChild) break;
      if (item.isComment && item.comment!.parentCid == parentCid) {
        childIndexList.add(cursor);
      } else if (item.isAction && item.parentCid == parentCid) {
        actionIndex = cursor;
      } else if (!item.isAction) {
        break;
      }
    }

    final hasMore = childIndexList.length < nextChildCount;
    itemList[rootIndex] = rootItem.copyWith(
      comment: rootItem.comment!.copyWith(childCount: nextChildCount),
      displayType: nextChildCount == 0
          ? CommentDisplayType.fatherCommentNoChild
          : CommentDisplayType.fatherCommentContainsChild,
    );

    for (var i = 0; i < childIndexList.length; i++) {
      final childIndex = childIndexList[i];
      final isLastLoaded = !hasMore && i == childIndexList.length - 1;
      itemList[childIndex] = itemList[childIndex].copyWith(
        displayType: isLastLoaded
            ? CommentDisplayType.childCommentLast
            : CommentDisplayType.childCommentMiddle,
      );
    }

    if (actionIndex == null) return;
    if (!hasMore || nextChildCount == 0) {
      itemList.removeAt(actionIndex);
      return;
    }
    itemList[actionIndex] = itemList[actionIndex].copyWith(
      totalChildCount: nextChildCount,
    );
  }

  void updateCommentByEffectiveId(
    List<CommentDisplayModel> items,
    String effectiveId,
    CommentModel Function(CommentModel comment) transform,
  ) {
    final index = items.indexWhere(
      (item) => item.isComment && item.comment!.effectiveId == effectiveId,
    );
    if (index == -1) return;
    items[index] = items[index].copyWith(
      comment: transform(items[index].comment!),
    );
  }
}
