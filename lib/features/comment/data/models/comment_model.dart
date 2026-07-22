import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';

abstract final class _CommentJsonParser {
  static int parseInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  static bool parseBoolLike(Object? value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == '1' || normalized == 'true';
    }
    return false;
  }

  static String parseString(Object? value) {
    return value?.toString().trim() ?? '';
  }
}

enum CommentSendState { normal, sending }

class CommentModel {
  const CommentModel({
    required this.cid,
    required this.tempId,
    required this.targetId,
    required this.parentCid,
    required this.userId,
    required this.userName,
    required this.avatar,
    required this.toUserId,
    required this.toUserName,
    required this.toAvatar,
    required this.content,
    required this.likeCount,
    required this.childCount,
    required this.createTime,
    required this.isLiked,
    required this.pictures,
    required this.children,
    required this.sendState,
  });

  final String cid;
  final String tempId;
  final String targetId;
  final String parentCid;
  final String userId;
  final String userName;
  final String? avatar;
  final String toUserId;
  final String toUserName;
  final String? toAvatar;
  final String content;
  final int likeCount;
  final int childCount;
  final int createTime;
  final bool isLiked;
  final List<TopicPictureModel> pictures;
  final List<CommentModel> children;
  final CommentSendState sendState;

  bool get isRoot => parentCid.isEmpty || parentCid == '0';
  bool get hasReplyTarget =>
      toUserId.isNotEmpty && toUserId != '0' && toUserName.isNotEmpty;
  bool get isPending => sendState == CommentSendState.sending;
  String get effectiveId => cid.isNotEmpty ? cid : tempId;
  String get displayContent {
    if (content.isNotEmpty) return content;
    if (pictures.isNotEmpty) return '[图片]';
    return '';
  }

  factory CommentModel.fromJson(Object? json) {
    if (json is! Map) {
      return const CommentModel(
        cid: '',
        tempId: '',
        targetId: '',
        parentCid: '',
        userId: '',
        userName: '',
        avatar: null,
        toUserId: '',
        toUserName: '',
        toAvatar: null,
        content: '',
        likeCount: 0,
        childCount: 0,
        createTime: 0,
        isLiked: false,
        pictures: <TopicPictureModel>[],
        children: <CommentModel>[],
        sendState: CommentSendState.normal,
      );
    }

    return CommentModel(
      cid: _CommentJsonParser.parseString(json['cid']),
      tempId: _CommentJsonParser.parseString(json['tempid']),
      targetId: _CommentJsonParser.parseString(json['tid']),
      parentCid: _CommentJsonParser.parseString(json['pcid']),
      userId: _CommentJsonParser.parseString(json['userid']),
      userName: _CommentJsonParser.parseString(json['name']),
      avatar: ValueUtil.getQiniuUrlByFileName(
        _CommentJsonParser.parseString(json['avatar']),
        thumbnail: true,
      ),
      toUserId: _CommentJsonParser.parseString(json['to_userid']),
      toUserName: _CommentJsonParser.parseString(json['to_name']),
      toAvatar: ValueUtil.getQiniuUrlByFileName(
        _CommentJsonParser.parseString(json['to_avatar']),
        thumbnail: true,
      ),
      content: _CommentJsonParser.parseString(json['content']),
      likeCount: _CommentJsonParser.parseInt(json['likecount']),
      childCount: _CommentJsonParser.parseInt(json['childcount']),
      createTime: _CommentJsonParser.parseInt(json['create_time']),
      isLiked: _CommentJsonParser.parseBoolLike(json['like']),
      pictures: TopicModel.parsePictures(json['pictures']),
      children: _parseChildren(json['items']),
      sendState: CommentSendState.normal,
    );
  }

  CommentModel copyWith({
    String? cid,
    String? tempId,
    String? targetId,
    String? parentCid,
    String? userId,
    String? userName,
    String? avatar,
    String? toUserId,
    String? toUserName,
    String? toAvatar,
    String? content,
    int? likeCount,
    int? childCount,
    int? createTime,
    bool? isLiked,
    List<TopicPictureModel>? pictures,
    List<CommentModel>? children,
    CommentSendState? sendState,
  }) {
    return CommentModel(
      cid: cid ?? this.cid,
      tempId: tempId ?? this.tempId,
      targetId: targetId ?? this.targetId,
      parentCid: parentCid ?? this.parentCid,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      avatar: avatar ?? this.avatar,
      toUserId: toUserId ?? this.toUserId,
      toUserName: toUserName ?? this.toUserName,
      toAvatar: toAvatar ?? this.toAvatar,
      content: content ?? this.content,
      likeCount: likeCount ?? this.likeCount,
      childCount: childCount ?? this.childCount,
      createTime: createTime ?? this.createTime,
      isLiked: isLiked ?? this.isLiked,
      pictures: pictures ?? this.pictures,
      children: children ?? this.children,
      sendState: sendState ?? this.sendState,
    );
  }

  static List<CommentModel> _parseChildren(Object? value) {
    if (value is! List) return const <CommentModel>[];

    return value
        .map((item) => CommentModel.fromJson(item))
        .where((item) => item.effectiveId.isNotEmpty)
        .toList(growable: false);
  }
}

class CommentPageResult {
  const CommentPageResult({
    required this.items,
    required this.hasMore,
    required this.total,
  });

  final List<CommentModel> items;
  final bool hasMore;
  final int total;

  factory CommentPageResult.fromJson(Object? json, {required int page}) {
    if (json is! Map) {
      return const CommentPageResult(
        items: <CommentModel>[],
        hasMore: false,
        total: 0,
      );
    }

    final rawItems = json['items'] as List<dynamic>? ?? <dynamic>[];
    final total = _CommentJsonParser.parseInt(json['total']);
    final totalPage = _CommentJsonParser.parseInt(json['totalpage']);
    final hasMore = json.containsKey('hasmore')
        ? _CommentJsonParser.parseBoolLike(json['hasmore'])
        : json.containsKey('hasMore')
        ? _CommentJsonParser.parseBoolLike(json['hasMore'])
        : totalPage > page;

    return CommentPageResult(
      items: rawItems
          .map((item) => CommentModel.fromJson(item))
          .where((item) => item.effectiveId.isNotEmpty)
          .toList(growable: false),
      hasMore: hasMore,
      total: total,
    );
  }
}

class CommentSubmitResult {
  const CommentSubmitResult({
    required this.cid,
    required this.tempId,
  });

  final String cid;
  final String tempId;

  factory CommentSubmitResult.fromJson(Object? json) {
    if (json is! Map) {
      return const CommentSubmitResult(cid: '', tempId: '');
    }

    return CommentSubmitResult(
      cid: _CommentJsonParser.parseString(json['cid']),
      tempId: _CommentJsonParser.parseString(json['tempid']),
    );
  }
}
