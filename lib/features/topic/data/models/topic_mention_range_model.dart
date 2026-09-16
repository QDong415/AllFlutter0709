/// 输入框中一段 @好友 的范围（不含尾随空格）。
class TopicMentionRangeModel {
  TopicMentionRangeModel({
    required this.userId,
    required this.from,
    required this.to,
  });

  final String userId;
  int from;
  int to;

  /// 删除区间是否完全包住这段 mention。
  bool isWrapped({required int start, required int end}) {
    return from >= start && to <= end;
  }

  /// 光标是否落在这段 mention 内部。
  bool containsOffset(int offset) {
    return offset > from && offset < to;
  }

  /// 把整段范围平移 [offset]。
  void shift(int offset) {
    from += offset;
    to += offset;
  }
}
