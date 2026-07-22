import 'package:all_flutter0709/features/comment/data/models/comment_model.dart';

enum CommentDisplayType {
  fatherCommentNoChild,
  fatherCommentContainsChild,
  childCommentMiddle,
  childCommentLast,
  showMoreComment,
  packUpComment,
  loadingMoreComment,
}

bool showCommentSeparator(CommentDisplayType displayType) {
  switch (displayType) {
    case CommentDisplayType.fatherCommentNoChild:
    case CommentDisplayType.childCommentLast:
    case CommentDisplayType.packUpComment:
      return true;
    case CommentDisplayType.fatherCommentContainsChild:
    case CommentDisplayType.childCommentMiddle:
    case CommentDisplayType.showMoreComment:
    case CommentDisplayType.loadingMoreComment:
      return false;
  }
}

class CommentDisplayModel {
  const CommentDisplayModel._({
    required this.isChild,
    this.comment,
    this.parentCid = '',
    this.startCid = '',
    this.totalChildCount = 0,
    this.displayType,
  });

  factory CommentDisplayModel.root(
    CommentModel comment, {
    required CommentDisplayType displayType,
  }) {
    return CommentDisplayModel._(
      comment: comment,
      isChild: false,
      displayType: displayType,
    );
  }

  factory CommentDisplayModel.child(
    CommentModel comment, {
    required CommentDisplayType displayType,
  }) {
    return CommentDisplayModel._(
      comment: comment,
      isChild: true,
      displayType: displayType,
    );
  }

  factory CommentDisplayModel.action({
    required String parentCid,
    required String startCid,
    required int totalChildCount,
    required CommentDisplayType displayType,
  }) {
    return CommentDisplayModel._(
      isChild: true,
      parentCid: parentCid,
      startCid: startCid,
      totalChildCount: totalChildCount,
      displayType: displayType,
    );
  }

  final bool isChild;
  final CommentModel? comment;
  final String parentCid;
  final String startCid;
  final int totalChildCount;
  final CommentDisplayType? displayType;

  bool get isAction =>
      displayType == CommentDisplayType.showMoreComment ||
      displayType == CommentDisplayType.packUpComment ||
      displayType == CommentDisplayType.loadingMoreComment;
  bool get isComment => comment != null;

  CommentDisplayModel copyWith({
    bool? isChild,
    CommentModel? comment,
    String? parentCid,
    String? startCid,
    int? totalChildCount,
    CommentDisplayType? displayType,
  }) {
    return CommentDisplayModel._(
      isChild: isChild ?? this.isChild,
      comment: comment ?? this.comment,
      parentCid: parentCid ?? this.parentCid,
      startCid: startCid ?? this.startCid,
      totalChildCount: totalChildCount ?? this.totalChildCount,
      displayType: displayType ?? this.displayType,
    );
  }
}
