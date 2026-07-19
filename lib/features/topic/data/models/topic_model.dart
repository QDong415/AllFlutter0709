import 'package:all_flutter0709/core/utils/value_util.dart';

abstract final class _TopicJsonParser {
  static int parseInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  static int? parseNullableInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static bool parseBoolLike(Object? value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  static String? parseNullableString(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}

class TopicPictureModel {
  const TopicPictureModel({required this.url, this.width, this.height});

  final String url;
  final int? width;
  final int? height;

  factory TopicPictureModel.fromJson(Object? json) {
    if (json is String) {
      return TopicPictureModel(
        url: ValueUtil.getQiniuUrlByFileName(json, max: true) ?? '',
      );
    }

    if (json is Map) {
      final filename =
          json['filename']?.toString() ??
          json['url']?.toString() ??
          json['picture']?.toString() ??
          '';
      return TopicPictureModel(
        url: ValueUtil.getQiniuUrlByFileName(filename, max: true) ?? '',
        width: _TopicJsonParser.parseNullableInt(json['width']),
        height: _TopicJsonParser.parseNullableInt(json['height']),
      );
    }

    return const TopicPictureModel(url: '');
  }
}

class TopicCommentModel {
  const TopicCommentModel({
    required this.cid,
    required this.userId,
    required this.tid,
    required this.content,
    required this.userName,
    required this.likeCount,
    required this.childCount,
    required this.createTime,
    required this.pictures,
    this.avatar,
  });

  final String cid;
  final String userId;
  final String tid;
  final String content;
  final String userName;
  final int likeCount;
  final int childCount;
  final int createTime;
  final List<TopicPictureModel> pictures;
  final String? avatar;

  factory TopicCommentModel.fromJson(Object? json) {
    if (json is! Map) {
      return const TopicCommentModel(
        cid: '',
        userId: '',
        tid: '',
        content: '',
        userName: '',
        likeCount: 0,
        childCount: 0,
        createTime: 0,
        pictures: <TopicPictureModel>[],
        avatar: null,
      );
    }

    return TopicCommentModel(
      cid: json['cid']?.toString() ?? '',
      userId: json['userid']?.toString() ?? '',
      tid: json['tid']?.toString() ?? '',
      content: _TopicJsonParser.parseNullableString(json['content']) ?? '',
      userName: json['name']?.toString() ?? '',
      likeCount: _TopicJsonParser.parseInt(json['likecount']),
      childCount: _TopicJsonParser.parseInt(json['childcount']),
      createTime: _TopicJsonParser.parseInt(json['create_time']),
      pictures: TopicModel.parsePictures(json['pictures']),
      avatar: ValueUtil.getQiniuUrlByFileName(json['avatar']?.toString()),
    );
  }
}

class TopicModel {
  const TopicModel({
    required this.tid,
    required this.userName,
    required this.isLiked,
    required this.likeCount,
    required this.commentCount,
    required this.createTime,
    required this.displayTime,
    required this.pictures,
    required this.comments,
    this.content,
    this.avatar,
  });

  final String tid;
  final String userName;
  final bool isLiked;
  final int likeCount;
  final int commentCount;
  final int createTime;
  final String displayTime;
  final List<TopicPictureModel> pictures;
  final List<TopicCommentModel> comments;
  final String? content;
  final String? avatar;

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      tid: json['tid']?.toString() ?? '',
      content: _TopicJsonParser.parseNullableString(json['content']),
      userName: json['name']?.toString() ?? 'Unknown',
      avatar: ValueUtil.getQiniuUrlByFileName(json['avatar']?.toString()),
      isLiked: _TopicJsonParser.parseBoolLike(json['like']),
      likeCount: _TopicJsonParser.parseInt(json['likecount']),
      commentCount: _TopicJsonParser.parseInt(json['commentcount']),
      createTime: _TopicJsonParser.parseInt(json['create_time']),
      displayTime: _formatTime(_TopicJsonParser.parseInt(json['create_time'])),
      pictures: parsePictures(json['pictures']),
      comments: _parseComments(json['comments']),
    );
  }

  TopicModel copyWith({
    String? tid,
    String? userName,
    bool? isLiked,
    int? likeCount,
    int? commentCount,
    int? createTime,
    String? displayTime,
    List<TopicPictureModel>? pictures,
    List<TopicCommentModel>? comments,
    String? content,
    String? avatar,
  }) {
    return TopicModel(
      tid: tid ?? this.tid,
      userName: userName ?? this.userName,
      isLiked: isLiked ?? this.isLiked,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createTime: createTime ?? this.createTime,
      displayTime: displayTime ?? this.displayTime,
      pictures: pictures ?? this.pictures,
      comments: comments ?? this.comments,
      content: content ?? this.content,
      avatar: avatar ?? this.avatar,
    );
  }

  static String _formatTime(int? timestamp) {
    if (timestamp == null || timestamp <= 0) return '--';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static List<TopicPictureModel> parsePictures(Object? value) {
    if (value is! List) return const <TopicPictureModel>[];

    return value
        .map((item) => TopicPictureModel.fromJson(item))
        .where((item) => item.url.isNotEmpty)
        .toList(growable: false);
  }

  static List<TopicCommentModel> _parseComments(Object? value) {
    if (value is! List) return const <TopicCommentModel>[];

    return value
        .map((item) => TopicCommentModel.fromJson(item))
        .where((item) => item.cid.isNotEmpty)
        .toList(growable: false);
  }
}
