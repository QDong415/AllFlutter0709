import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';

/// 赞 / 评论 / @我 列表中的一条提醒，对齐 Android `RemindBean`。
class RemindModel {
  const RemindModel({
    required this.actorUserId,
    required this.actorName,
    required this.actorAvatar,
    required this.content,
    required this.topicId,
    required this.topicUserId,
    required this.topicUserName,
    required this.topicContent,
    required this.topicUserAvatar,
    required this.pictures,
    required this.createTime,
  });

  final String actorUserId;
  final String actorName;
  final String? actorAvatar;
  final String content;
  final String topicId;
  final String topicUserId;
  final String topicUserName;
  final String topicContent;
  final String? topicUserAvatar;
  final List<TopicPictureModel> pictures;
  final int createTime;

  /// 相对时间文案。
  String get displayTime => ValueUtil.getTimeStringFromNow(createTime);

  factory RemindModel.fromJson(Map<String, dynamic> json) {
    return RemindModel(
      actorUserId: json['comment_userid']?.toString() ?? '',
      actorName: json['comment_user_name']?.toString() ?? '',
      actorAvatar: json['comment_user_avatar']?.toString(),
      content: json['comment_content']?.toString() ?? '',
      topicId: json['tid']?.toString() ?? '',
      topicUserId: json['topic_userid']?.toString() ?? '',
      topicUserName: json['topic_user_name']?.toString() ?? '',
      topicContent: json['topic_content']?.toString() ?? '',
      topicUserAvatar: json['topic_user_avatar']?.toString(),
      pictures: TopicModel.parsePictures(json['pictures']),
      createTime: int.tryParse(json['create_time']?.toString() ?? '') ?? 0,
    );
  }
}
