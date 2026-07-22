import 'package:all_flutter0709/core/account/account.dart';
import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:all_flutter0709/features/comment/data/comment_repository.dart';
import 'package:all_flutter0709/features/comment/data/models/comment_model.dart';

class CommentReplyTarget {
  const CommentReplyTarget({
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

/// 评论发送：构造乐观评论 + 提交服务端。不依赖 Riverpod，也不改列表。
class CommentSendHelper {
  const CommentSendHelper({
    this.repository = const CommentRepository(),
  });

  final CommentRepository repository;

  CommentModel buildLocalComment({
    required AccountModel account,
    required String targetId,
    required String content,
    CommentReplyTarget? replyTarget,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final tempId = DateTime.now().microsecondsSinceEpoch.toString();

    return CommentModel(
      cid: '',
      tempId: tempId,
      targetId: targetId,
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

  Future<CommentSubmitResult> submit({
    required String targetId,
    required CommentTargetType type,
    required CommentModel localComment,
  }) {
    return repository.submitComment(
      targetId: targetId,
      type: type,
      content: localComment.content,
      tempId: localComment.tempId,
      parentCid: localComment.isRoot ? null : localComment.parentCid,
      toUserId: localComment.toUserId,
      toUserName: localComment.toUserName,
    );
  }
}
