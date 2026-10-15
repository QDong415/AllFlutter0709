import 'package:all_flutter0709/core/utils/value_util.dart';

/// 用户自定义 AI 的草稿与生图状态。
class AiCreationModel {
  const AiCreationModel({
    required this.creationId,
    required this.status,
    required this.name,
    required this.gender,
    required this.personality,
    required this.outfit,
    required this.career,
    required this.moderationStatus,
    required this.moderationCode,
    required this.avatarImage,
    required this.fullBodyImage,
    required this.errorMessage,
    required this.aiUserId,
  });

  final int creationId;
  final String status;
  final String name;
  final int gender;
  final String personality;
  final String outfit;
  final String career;
  final String moderationStatus;
  final String moderationCode;
  final String avatarImage;
  final String fullBodyImage;
  final String errorMessage;
  final String aiUserId;

  String? get avatarUrl =>
      ValueUtil.getQiniuUrlByFileName(avatarImage, keepOriginal: true);

  String? get fullBodyImageUrl =>
      ValueUtil.getQiniuUrlByFileName(fullBodyImage, keepOriginal: true);

  bool get isReady => status == 'ready';
  bool get isPublished => status == 'published';

  factory AiCreationModel.fromJson(Map<String, dynamic> json) {
    return AiCreationModel(
      creationId: _intOf(json['creation_id']),
      status: json['status']?.toString() ?? 'draft',
      name: json['name']?.toString() ?? '',
      gender: _intOf(json['gender']),
      personality: json['personality']?.toString() ?? '',
      outfit: json['outfit']?.toString() ?? '',
      career: json['career']?.toString() ?? '',
      moderationStatus: json['moderation_status']?.toString() ?? 'empty',
      moderationCode: json['moderation_code']?.toString() ?? '',
      avatarImage: json['avatar_image']?.toString() ?? '',
      fullBodyImage: json['full_body_image']?.toString() ?? '',
      errorMessage: json['error_message']?.toString() ?? '',
      aiUserId: json['ai_userid']?.toString() ?? '',
    );
  }

  static int _intOf(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
