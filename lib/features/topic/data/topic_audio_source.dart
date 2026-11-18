import 'dart:io';

import 'package:all_flutter0709/core/utils/value_util.dart';
import 'package:all_flutter0709/features/comment/data/models/comment_model.dart';
import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';

/// 动态 / 评论共用的语音播放源。
class TopicAudioSource {
  const TopicAudioSource({
    required this.playKey,
    required this.audioFileName,
    required this.audioDurationSeconds,
    this.localFile,
  });

  final String playKey;
  final String audioFileName;
  final int audioDurationSeconds;
  final File? localFile;

  bool get hasRemoteAudio => audioFileName.trim().isNotEmpty;

  bool get canPlay =>
      hasRemoteAudio || (localFile != null && localFile!.path.isNotEmpty);

  String get audioUrl =>
      ValueUtil.getVideoUrlByFileName(audioFileName.trim()) ?? '';

  factory TopicAudioSource.fromTopic(TopicModel topic) {
    return TopicAudioSource(
      playKey: topic.tid.trim(),
      audioFileName: topic.audioFileName,
      audioDurationSeconds: topic.audioDurationSeconds,
    );
  }

  factory TopicAudioSource.fromComment(CommentModel comment) {
    return TopicAudioSource(
      playKey: 'c:${comment.effectiveId}',
      audioFileName: comment.audioFileName,
      audioDurationSeconds: comment.audioDurationSeconds,
      localFile: comment.localAudioFile,
    );
  }
}