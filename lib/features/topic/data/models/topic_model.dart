import 'package:all_flutter0709/core/utils/value_util.dart';

class TopicModel {
  const TopicModel({
    required this.tid,
    required this.userName,
    required this.likeCount,
    required this.commentCount,
    required this.createTime,
    required this.displayTime,
    this.content,
    this.avatar,
  });

  final String tid;
  final String userName;
  final int likeCount;
  final int commentCount;
  final int createTime;
  final String displayTime;
  final String? content;
  final String? avatar;

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      tid: json['tid']?.toString() ?? '',
      content: json['content'] as String?,
      userName: json['name'] as String? ?? 'Unknown',
      avatar: ValueUtil.getQiniuUrlByFileName(json['avatar']?.toString()),
      likeCount: (json['likecount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentcount'] as num?)?.toInt() ?? 0,
      createTime: (json['create_time'] as num?)?.toInt() ?? 0,
      displayTime: _formatTime((json['create_time'] as num?)?.toInt() ?? 0),
    );
  }

  static String _formatTime(int timestamp) {
    if (timestamp <= 0) return '--';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
