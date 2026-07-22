import 'package:all_flutter0709/core/utils/value_util.dart';

abstract final class _VideoJsonParser {
  static int parseInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
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

class VideoModel {
  const VideoModel({
    required this.videoId,
    required this.videoUrl,
    required this.coverUrl,
    required this.content,
    required this.width,
    required this.height,
    required this.createTime,
    required this.displayTime,
    required this.isLiked,
    required this.readCount,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.userId,
    required this.userName,
    required this.avatarUrl,
  });

  final String videoId;
  final String? videoUrl;
  final String? coverUrl;
  final String content;
  final int width;
  final int height;
  final int createTime;
  final String displayTime;
  final bool isLiked;
  final int readCount;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final String userId;
  final String userName;
  final String? avatarUrl;

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    final createTime = _VideoJsonParser.parseInt(json['create_time']);
    return VideoModel(
      videoId: json['videoid']?.toString() ?? '',
      videoUrl: ValueUtil.getQiniuUrlByFileName(
        _VideoJsonParser.parseNullableString(json['videourl']),
        keepOriginal: true,
      ),
      coverUrl: ValueUtil.getQiniuUrlByFileName(
        _VideoJsonParser.parseNullableString(json['cover']),
        keepOriginal: true,
      ),
      content: _VideoJsonParser.parseNullableString(json['content']) ?? '',
      width: _VideoJsonParser.parseInt(json['width']),
      height: _VideoJsonParser.parseInt(json['height']),
      createTime: createTime,
      displayTime: _formatTime(createTime),
      isLiked: _VideoJsonParser.parseBoolLike(json['like']),
      readCount: _VideoJsonParser.parseInt(json['readcount']),
      likeCount: _VideoJsonParser.parseInt(json['likecount']),
      commentCount: _VideoJsonParser.parseInt(json['commentcount']),
      shareCount: _VideoJsonParser.parseInt(json['sharecount']),
      userId: json['userid']?.toString() ?? '',
      userName: json['name']?.toString() ?? 'Unknown',
      avatarUrl: ValueUtil.getQiniuUrlByFileName(
        _VideoJsonParser.parseNullableString(json['avatar']),
        thumbnail: true,
      ),
    );
  }

  VideoModel copyWith({
    String? videoId,
    String? videoUrl,
    String? coverUrl,
    String? content,
    int? width,
    int? height,
    int? createTime,
    String? displayTime,
    bool? isLiked,
    int? readCount,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    String? userId,
    String? userName,
    String? avatarUrl,
  }) {
    return VideoModel(
      videoId: videoId ?? this.videoId,
      videoUrl: videoUrl ?? this.videoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      content: content ?? this.content,
      width: width ?? this.width,
      height: height ?? this.height,
      createTime: createTime ?? this.createTime,
      displayTime: displayTime ?? this.displayTime,
      isLiked: isLiked ?? this.isLiked,
      readCount: readCount ?? this.readCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  String get displayDate {
    if (createTime <= 0) return '--';
    final date = DateTime.fromMillisecondsSinceEpoch(createTime * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String _formatTime(int timestamp) {
    if (timestamp <= 0) return '--';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
