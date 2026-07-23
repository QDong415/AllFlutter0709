import 'dart:convert';

import 'package:all_flutter0709/core/utils/value_util.dart';

enum ConversationMessageType {
  text(1),
  image(2),
  voice(3),
  callAudio(10),
  callVideo(11);

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
  });

  final int? localId;
  final int msgId;
  final String clientMessageId;
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

  DateTime get createTime =>
      DateTime.fromMillisecondsSinceEpoch(createTimeSeconds * 1000);

  String get avatarUrl =>
      ValueUtil.getQiniuUrlByFileName(otherPhoto, keepOriginal: true) ?? '';

  bool get isImage => messageType == ConversationMessageType.image;

  String? get imageUrl => isImage
      ? ValueUtil.getQiniuUrlByFileName(filename, keepOriginal: true)
      : null;

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
      case ConversationMessageType.callAudio:
        return '[语音通话]';
      case ConversationMessageType.callVideo:
        return '[视频通话]';
      case ConversationMessageType.text:
        return content;
    }
  }

  ConversationMessage copyWith({
    int? localId,
    int? msgId,
    String? clientMessageId,
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
    };
  }

  factory ConversationMessage.fromDbMap(Map<String, Object?> map) {
    return ConversationMessage(
      localId: _readNullableInt(map['dbid']),
      msgId: _readInt(map['msgid']),
      clientMessageId: _readString(map['client_messageid']),
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
    );
  }

  factory ConversationMessage.fromApiJson(Map<String, dynamic> json) {
    final type = _readInt(json['type'], fallback: 1);
    final subtype = _readInt(json['subtype'], fallback: 1);
    final otherUserId = _readString(json['other_userid']);
    final targetId = _readString(json['targetid']);
    return ConversationMessage(
      msgId: _readInt(json['msgid']),
      clientMessageId: _readString(json['client_messageid']),
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
      extend: _readString(json['extend']),
      isSender: false,
      isRead: false,
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
