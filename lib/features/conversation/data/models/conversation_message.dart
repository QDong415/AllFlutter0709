import 'dart:convert';

import 'package:all_flutter0709/core/account/user_type.dart';
import 'package:all_flutter0709/core/utils/value_util.dart';

enum ConversationMessageType {
  text(1),
  image(2),
  voice(3),

  /// 礼物。金币扣减在 gift/send，这条消息只负责展示。
  gift(4),

  /// 居中灰字 tips，例如 AI 生图扣费提醒。
  tips(5),

  /// 分享的动态卡片。展示快照在 extend JSON，点开再拉详情。
  topic(6),
  callAudio(10),
  callVideo(11),

  /// 撤回后的占位。正文已清空，界面显示居中提示。
  recall(88);

  const ConversationMessageType(this.subtype);

  final int subtype;

  static ConversationMessageType fromSubtype(int value) {
    return ConversationMessageType.values.firstWhere(
      (item) => item.subtype == value,
      orElse: () => ConversationMessageType.text,
    );
  }
}

enum ConversationMessageStatus {
  sending(0),
  sent(1),
  failed(2);

  const ConversationMessageStatus(this.code);

  final int code;

  static ConversationMessageStatus fromCode(int value) {
    return ConversationMessageStatus.values.firstWhere(
      (item) => item.code == value,
      orElse: () => ConversationMessageStatus.sent,
    );
  }
}

class ConversationMessage {
  const ConversationMessage({
    this.localId,
    required this.msgId,
    required this.clientMessageId,
    required this.conversationId,
    required this.otherUserId,
    required this.otherName,
    required this.otherPhoto,
    required this.content,
    required this.createTimeSeconds,
    required this.status,
    required this.type,
    required this.messageType,
    required this.filename,
    required this.extend,
    required this.isSender,
    required this.isRead,
    this.localFilePath = '',
    this.uploadProgress = 0,
    this.otherUserType = UserType.human,
  });

  final int? localId;
  final int msgId;

  /// 发送方本地生成的消息 id。同一用户下不重复即可，不是全局唯一。
  final int clientMessageId;
  final String conversationId;
  final String otherUserId;
  final String otherName;
  final String otherPhoto;
  final String content;
  final int createTimeSeconds;
  final ConversationMessageStatus status;
  final int type;
  final ConversationMessageType messageType;
  final String filename;
  final String extend;
  final bool isSender;
  final bool isRead;
  final String localFilePath;
  final int uploadProgress;

  /// 对方账号类型：0 真人 / 1 AI。
  final int otherUserType;

  /// 对方是否为 AI 账号。
  bool get isAi => UserType.isAi(otherUserType);

  /// 发送后允许撤回的秒数，与服务端 `CHAT_RECALL_WINDOW_SECONDS` 一致。
  static const recallWindowSeconds = 120;

  /// 是否为撤回占位。
  bool get isRecall => messageType == ConversationMessageType.recall;

  /// 是否为居中 tips。
  bool get isTips => messageType == ConversationMessageType.tips;

  /// 撤回提示文案。发送方和接收方不同。
  String get recallLabel => isSender ? '你撤回了一条消息' : '对方撤回了一条消息';

  /// 展示层稳定 id：优先客户端 id，其次服务端 msgid，再次本地 dbid。
  String get itemId {
    if (clientMessageId > 0) {
      return '$clientMessageId';
    }
    if (msgId != 0) {
      return 'msg_$msgId';
    }
    if (localId != null) {
      return 'local_$localId';
    }
    return 'tmp_${createTimeSeconds}_${messageType.subtype}_${content.hashCode}';
  }

  DateTime get createTime =>
      DateTime.fromMillisecondsSinceEpoch(createTimeSeconds * 1000);

  String get avatarUrl =>
      ValueUtil.getQiniuUrlByFileName(otherPhoto, keepOriginal: true) ?? '';

  bool get isImage => messageType == ConversationMessageType.image;

  /// 礼物图文件名。优先 extend.picture，其次 filename。
  String get giftPicture {
    if (messageType != ConversationMessageType.gift) {
      return '';
    }
    final picture = _extendJsonMap()?['picture']?.toString().trim() ?? '';
    if (picture.isNotEmpty) {
      return picture;
    }
    return filename;
  }

  /// 礼物名称。
  String get giftTitle {
    if (messageType != ConversationMessageType.gift) {
      return '';
    }
    final title = _extendJsonMap()?['title']?.toString().trim() ?? '';
    if (title.isNotEmpty) {
      return title;
    }
    var text = content.replaceFirst('[礼物]', '').trim();
    final match = RegExp(r'^(.+?)\s+x(\d+)$').firstMatch(text);
    if (match != null) {
      text = match.group(1)!.trim();
    }
    return text;
  }

  /// 本次送出数量。
  int get giftCount {
    if (messageType != ConversationMessageType.gift) {
      return 0;
    }
    final raw = _extendJsonMap()?['count'];
    final fromJson = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
    if (fromJson != null && fromJson > 0) {
      return fromJson;
    }
    // Buddy 把数量直接放在 extend，例如 "1"。
    final plain = int.tryParse(extend.trim());
    if (plain != null && plain > 0) {
      return plain;
    }
    return 1;
  }

  String? get imageUrl => isImage
      ? ValueUtil.getQiniuUrlByFileName(filename, keepOriginal: true)
      : null;

  /// 语音远端地址；filename 为空时为 null。下载/播放必须用原文件，不要加 imageView。
  String? get voiceUrl {
    if (messageType != ConversationMessageType.voice) {
      return null;
    }
    return ValueUtil.getQiniuUrlByFileName(filename, keepOriginal: true);
  }

  /// 语音时长（秒）；对齐 Android extend.duration。
  int get voiceSeconds {
    if (messageType != ConversationMessageType.voice) {
      return 1;
    }
    final fromExtend = _readExtendInt('duration');
    if (fromExtend != null && fromExtend > 0) {
      return fromExtend;
    }
    final fromContent = int.tryParse(content.trim());
    if (fromContent != null && fromContent > 0) {
      return fromContent;
    }
    return 1;
  }

  /// 是否已播放；对齐 Android：extend 含 `hadplay` 即为已读。
  bool get voiceHadPlay {
    if (messageType != ConversationMessageType.voice) {
      return true;
    }
    final map = _extendJsonMap();
    return map != null && map.containsKey('hadplay');
  }

  /// 生成语音 extend，对齐 Android `{"duration":"3","hadplay":"1"}`。
  static String voiceExtendJson({
    required int durationSeconds,
    required bool hadPlay,
  }) {
    final map = <String, String>{'duration': '$durationSeconds'};
    if (hadPlay) {
      map['hadplay'] = '1';
    }
    return jsonEncode(map);
  }

  /// 生成动态分享 extend；字段仅够画气泡，详情靠 [topicTid] 再请求。
  static String topicExtendJson({
    required String tid,
    required String content,
    required String picture,
    required String userId,
    required String name,
    required String avatar,
    required bool hasVideo,
  }) {
    return jsonEncode(<String, dynamic>{
      'tid': tid,
      'content': content,
      'picture': picture,
      'userid': userId,
      'name': name,
      'avatar': avatar,
      'has_video': hasVideo ? 1 : 0,
    });
  }

  /// 动态 id。
  String get topicTid {
    if (messageType != ConversationMessageType.topic) {
      return '';
    }
    return _extendJsonMap()?['tid']?.toString().trim() ?? '';
  }

  /// 动态正文快照。
  String get topicContent {
    if (messageType != ConversationMessageType.topic) {
      return '';
    }
    return _extendJsonMap()?['content']?.toString().trim() ?? '';
  }

  /// 动态封面（filename 或完整 URL）；视频动态一般为 pictures 首图。
  String get topicPicture {
    if (messageType != ConversationMessageType.topic) {
      return '';
    }
    return _extendJsonMap()?['picture']?.toString().trim() ?? '';
  }

  /// 动态作者 id。
  String get topicAuthorUserId {
    if (messageType != ConversationMessageType.topic) {
      return '';
    }
    return _extendJsonMap()?['userid']?.toString().trim() ?? '';
  }

  /// 动态作者昵称。
  String get topicAuthorName {
    if (messageType != ConversationMessageType.topic) {
      return '';
    }
    return _extendJsonMap()?['name']?.toString().trim() ?? '';
  }

  /// 动态作者头像（filename 或完整 URL）。
  String get topicAuthorAvatar {
    if (messageType != ConversationMessageType.topic) {
      return '';
    }
    return _extendJsonMap()?['avatar']?.toString().trim() ?? '';
  }

  /// 是否视频动态。
  bool get topicHasVideo {
    if (messageType != ConversationMessageType.topic) {
      return false;
    }
    final raw = _extendJsonMap()?['has_video'];
    if (raw is bool) {
      return raw;
    }
    if (raw is num) {
      return raw != 0;
    }
    final text = raw?.toString().trim() ?? '';
    return text == '1' || text.toLowerCase() == 'true';
  }

  /// 去掉接收语音里发送方带来的 hadplay，接收方应视为未读。
  static String stripIncomingVoiceHadPlay(String extend) {
    if (extend.trim().isEmpty) {
      return extend;
    }
    try {
      final json = jsonDecode(extend);
      if (json is! Map) {
        return extend;
      }
      final map = Map<String, dynamic>.from(
        json.map((key, value) => MapEntry(key.toString(), value)),
      );
      if (!map.containsKey('hadplay')) {
        return extend;
      }
      map.remove('hadplay');
      return jsonEncode(map);
    } catch (_) {
      return extend;
    }
  }

  Map<String, dynamic>? _extendJsonMap() {
    if (extend.trim().isEmpty) {
      return null;
    }
    try {
      final json = jsonDecode(extend);
      if (json is Map<String, dynamic>) {
        return json;
      }
      if (json is Map) {
        return json.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {}
    return null;
  }

  int? _readExtendInt(String key) {
    final map = _extendJsonMap();
    if (map == null) {
      return null;
    }
    final value = _readInt(map[key], fallback: -1);
    return value > 0 ? value : null;
  }

  Map<String, int> get imageSize {
    if (!isImage || extend.trim().isEmpty) {
      return const {'width': 1080, 'height': 1439};
    }

    try {
      final json = jsonDecode(extend);
      if (json is! Map) {
        return const {'width': 1080, 'height': 1439};
      }
      return {
        'width': _readInt(json['width'], fallback: 1080),
        'height': _readInt(json['height'], fallback: 1439),
      };
    } catch (_) {
      return const {'width': 1080, 'height': 1439};
    }
  }

  String get previewText {
    switch (messageType) {
      case ConversationMessageType.image:
        return '[图片消息]';
      case ConversationMessageType.voice:
        return '[语音消息]';
      case ConversationMessageType.gift:
        return content.isEmpty ? '[礼物]' : content;
      case ConversationMessageType.topic:
        return content.isEmpty ? '[动态]' : content;
      case ConversationMessageType.tips:
        return content;
      case ConversationMessageType.callAudio:
        return '[语音通话]';
      case ConversationMessageType.callVideo:
        return '[视频通话]';
      case ConversationMessageType.recall:
        return recallLabel;
      case ConversationMessageType.text:
        return content;
    }
  }

  ConversationMessage copyWith({
    int? localId,
    int? msgId,
    int? clientMessageId,
    String? conversationId,
    String? otherUserId,
    String? otherName,
    String? otherPhoto,
    String? content,
    int? createTimeSeconds,
    ConversationMessageStatus? status,
    int? type,
    ConversationMessageType? messageType,
    String? filename,
    String? extend,
    bool? isSender,
    bool? isRead,
    String? localFilePath,
    int? uploadProgress,
    int? otherUserType,
  }) {
    return ConversationMessage(
      localId: localId ?? this.localId,
      msgId: msgId ?? this.msgId,
      clientMessageId: clientMessageId ?? this.clientMessageId,
      conversationId: conversationId ?? this.conversationId,
      otherUserId: otherUserId ?? this.otherUserId,
      otherName: otherName ?? this.otherName,
      otherPhoto: otherPhoto ?? this.otherPhoto,
      content: content ?? this.content,
      createTimeSeconds: createTimeSeconds ?? this.createTimeSeconds,
      status: status ?? this.status,
      type: type ?? this.type,
      messageType: messageType ?? this.messageType,
      filename: filename ?? this.filename,
      extend: extend ?? this.extend,
      isSender: isSender ?? this.isSender,
      isRead: isRead ?? this.isRead,
      localFilePath: localFilePath ?? this.localFilePath,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      otherUserType: otherUserType ?? this.otherUserType,
    );
  }

  Map<String, Object?> toDbMap({required String userId}) {
    return {
      'dbid': localId,
      'userid': userId,
      'msgid': msgId,
      'client_messageid': clientMessageId,
      'targetid': conversationId,
      'other_userid': otherUserId,
      'other_name': otherName,
      'other_photo': otherPhoto,
      'content': content,
      'create_time': createTimeSeconds,
      'state': status.code,
      'type': type,
      'subtype': messageType.subtype,
      'filename': filename,
      'extend': extend,
      'issender': isSender ? 1 : 0,
      'hadread': isRead ? 1 : 0,
      'local_file_path': localFilePath,
      'upload_progress': uploadProgress,
      'other_user_type': otherUserType,
    };
  }

  factory ConversationMessage.fromDbMap(Map<String, Object?> map) {
    return ConversationMessage(
      localId: _readNullableInt(map['dbid']),
      msgId: _readInt(map['msgid']),
      clientMessageId: _readInt(map['client_messageid']),
      conversationId: _readString(map['targetid']),
      otherUserId: _readString(map['other_userid']),
      otherName: _readString(map['other_name']),
      otherPhoto: _readString(map['other_photo']),
      content: _readString(map['content']),
      createTimeSeconds: _readInt(map['create_time']),
      status: ConversationMessageStatus.fromCode(_readInt(map['state'])),
      type: _readInt(map['type'], fallback: 1),
      messageType: ConversationMessageType.fromSubtype(
        _readInt(map['subtype']),
      ),
      filename: _readString(map['filename']),
      extend: _readString(map['extend']),
      isSender: _readInt(map['issender']) == 1,
      isRead: _readInt(map['hadread']) == 1,
      localFilePath: _readString(map['local_file_path']),
      uploadProgress: _readInt(map['upload_progress']),
      otherUserType: UserType.parse(map['other_user_type']),
    );
  }

  factory ConversationMessage.fromApiJson(Map<String, dynamic> json) {
    final type = _readInt(json['type'], fallback: 1);
    final subtype = _readInt(json['subtype'], fallback: 1);
    final otherUserId = _readString(json['other_userid']);
    final targetId = _readString(json['targetid']);
    final rawExtend = _readString(json['extend']);
    final extend = subtype == ConversationMessageType.voice.subtype
        ? stripIncomingVoiceHadPlay(rawExtend)
        : rawExtend;
    return ConversationMessage(
      msgId: _readInt(json['msgid']),
      clientMessageId: _readInt(json['client_messageid']),
      conversationId: type == 1 && otherUserId.isNotEmpty
          ? otherUserId
          : targetId,
      otherUserId: otherUserId,
      otherName: _readString(json['other_name']),
      otherPhoto: _readString(json['other_photo']),
      content: _readString(json['content']),
      createTimeSeconds: _readInt(json['create_time']),
      status: ConversationMessageStatus.sent,
      type: type,
      messageType: ConversationMessageType.fromSubtype(subtype),
      filename: _readString(json['filename']),
      extend: extend,
      isSender: false,
      isRead: false,
      otherUserType: UserType.parse(json['other_user_type']),
    );
  }

  static String _readString(Object? value) => value?.toString().trim() ?? '';

  static int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static int? _readNullableInt(Object? value) {
    if (value == null) {
      return null;
    }
    return _readInt(value);
  }
}
