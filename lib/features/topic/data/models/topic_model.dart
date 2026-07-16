class TopicModel {
  const TopicModel({
    required this.tid,
    required this.userName,
    required this.likeCount,
    required this.commentCount,
    required this.createTime,
    this.content,
    this.avatar,
  });

  final String tid;
  final String userName;
  final int likeCount;
  final int commentCount;
  final int createTime;
  final String? content;
  final String? avatar;

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      tid: json['tid']?.toString() ?? '',
      content: json['content'] as String?,
      userName: json['name'] as String? ?? 'Unknown',
      avatar: json['avatar'] as String?,
      likeCount: (json['likecount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentcount'] as num?)?.toInt() ?? 0,
      createTime: (json['create_time'] as num?)?.toInt() ?? 0,
    );
  }
}
