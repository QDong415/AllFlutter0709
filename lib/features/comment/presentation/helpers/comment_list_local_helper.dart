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
