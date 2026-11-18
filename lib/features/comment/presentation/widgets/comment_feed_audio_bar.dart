import 'dart:async';

import 'package:all_flutter0709/features/comment/data/models/comment_model.dart';
import 'package:all_flutter0709/features/topic/data/topic_audio_source.dart';
import 'package:all_flutter0709/features/topic/presentation/controllers/topic_audio_play_controller.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_audio_bar.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_feed_audio_bar.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 评论列表里的语音条。
class CommentFeedAudioBar extends ConsumerWidget {
  const CommentFeedAudioBar({super.key, required this.comment});

  final CommentModel comment;

  TopicAudioSource get _source => TopicAudioSource.fromComment(comment);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(topicAudioPlayControllerProvider);
    final key = _source.playKey;
    final active = controller.targetPlayKey == key;
    final loading = active && controller.phase == TopicAudioPhase.loading;
    final playing = active && controller.phase == TopicAudioPhase.playing;
    final showProgress =
        active &&
        (controller.phase == TopicAudioPhase.playing ||
            controller.phase == TopicAudioPhase.paused);
    final seconds = showProgress
        ? controller.positionSeconds
        : comment.audioDurationSeconds;
    return TopicAudioVisibility(
      playKey: key,
      child: TopicAudioBar(
        durationSeconds: comment.audioDurationSeconds,
        progress: showProgress ? controller.progress : 0,
        timeLabel: _formatClock(seconds),
        playing: playing,
        loading: loading,
        onTap: () {
          final before = controller.errorNonce;
          unawaited(_play(context, ref, before));
        },
      ),
    );
  }

  Future<void> _play(BuildContext context, WidgetRef ref, int before) async {
    await ref.read(topicAudioPlayControllerProvider).onTapSource(_source);
    if (!context.mounted) {
      return;
    }
    final controller = ref.read(topicAudioPlayControllerProvider);
    if (controller.errorNonce != before && controller.errorText.isNotEmpty) {
      AppToast.show(context, controller.errorText);
    }
  }

  String _formatClock(int totalSeconds) {
    final safe = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = (safe ~/ 60).toString().padLeft(2, '0');
    final seconds = (safe % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}