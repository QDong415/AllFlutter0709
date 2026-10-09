import 'dart:async';

import 'package:all_flutter0709/features/topic/data/topic_repository.dart';

/// 动态点赞状态变更，对齐 Android `TopicLikeEvent`（type = 1，动态本身）。
class TopicLikeEvent {
  const TopicLikeEvent({
    required this.tid,
    required this.isLiked,
    required this.likeCount,
  });

  /// 动态 id。
  final String tid;

  /// 变更后的点赞状态。
  final bool isLiked;

  /// 变更后的点赞数。
  final int likeCount;
}

/// 动态点赞的公共入口：先广播乐观状态，失败再广播回滚。
abstract final class TopicLikeHelper {
  static const TopicRepository _repository = TopicRepository();

  /// 点赞状态广播流。列表、详情各自订阅后本地更新。
  static final StreamController<TopicLikeEvent> controller =
      StreamController<TopicLikeEvent>.broadcast();

  /// 切换点赞。成功前先发出目标状态，失败时发出原状态并重新抛出异常。
  static Future<void> toggle({
    required String tid,
    required bool isLiked,
    required int likeCount,
  }) async {
    final id = tid.trim();
    if (id.isEmpty) {
      throw Exception('缺少动态id');
    }

    final nextIsLiked = !isLiked;
    final nextLikeCount = nextIsLiked
        ? likeCount + 1
        : (likeCount > 0 ? likeCount - 1 : 0);

    controller.add(
      TopicLikeEvent(tid: id, isLiked: nextIsLiked, likeCount: nextLikeCount),
    );

    try {
      await _repository.likeTopic(
        tid: id,
        isLiked: isLiked,
        likeCount: likeCount,
      );
    } catch (error) {
      controller.add(
        TopicLikeEvent(tid: id, isLiked: isLiked, likeCount: likeCount),
      );
      rethrow;
    }
  }
}
