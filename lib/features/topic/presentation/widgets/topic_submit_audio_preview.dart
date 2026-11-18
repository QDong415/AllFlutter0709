import 'dart:async';
import 'dart:io';

import 'package:all_flutter0709/app/theme/app_palette.dart';
import 'package:all_flutter0709/core/audio/app_audio_playback_coordinator.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_audio_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// 发布页里试听刚录好的语音，不进入信息流播放器。
class TopicSubmitAudioPreview extends StatefulWidget {
  const TopicSubmitAudioPreview({
    super.key,
    required this.file,
    required this.durationSeconds,
    required this.onDelete,
  });

  final File file;
  final int durationSeconds;
  final VoidCallback onDelete;

  @override
  State<TopicSubmitAudioPreview> createState() =>
      _TopicSubmitAudioPreviewState();
}

class _TopicSubmitAudioPreviewState extends State<TopicSubmitAudioPreview> {
  final AudioPlayer _player = AudioPlayer();
  final Object _playbackOwner = Object();
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;
  bool _playing = false;
  double _progress = 0;
  int _positionSeconds = 0;

  @override
  void initState() {
    super.initState();
    _positionSubscription = _player.positionStream.listen((position) {
      if (!mounted) {
        return;
      }
      final totalMs = widget.durationSeconds * 1000;
      setState(() {
        _positionSeconds = position.inSeconds;
        _progress = totalMs <= 0
            ? 0
            : (position.inMilliseconds / totalMs).clamp(0.0, 1.0);
      });
    });
    _stateSubscription = _player.playerStateStream.listen((state) {
      if (!mounted) {
        return;
      }
      if (state.processingState == ProcessingState.completed) {
        AppAudioPlaybackCoordinator.instance.release(_playbackOwner);
        setState(() {
          _playing = false;
          _progress = 0;
          _positionSeconds = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    AppAudioPlaybackCoordinator.instance.release(_playbackOwner);
    _positionSubscription?.cancel();
    _stateSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      AppAudioPlaybackCoordinator.instance.release(_playbackOwner);
      await _player.pause();
      if (mounted) {
        setState(() => _playing = false);
      }
      return;
    }
    if (_player.processingState == ProcessingState.idle) {
      await _player.setFilePath(widget.file.path);
    } else if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }
    await AppAudioPlaybackCoordinator.instance.start(
      owner: _playbackOwner,
      stop: _stopForCoordinator,
      start: () {
        if (mounted) {
          setState(() => _playing = true);
        }
        unawaited(_player.play());
      },
    );
  }

  Future<void> _stopForCoordinator() async {
    if (mounted) {
      setState(() {
        _playing = false;
        _progress = 0;
        _positionSeconds = 0;
      });
    }
    await _player.stop();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _playing || _progress > 0
        ? _positionSeconds
        : widget.durationSeconds;
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remain = (seconds % 60).toString().padLeft(2, '0');
    return Row(
      children: [
        TopicAudioBar(
          durationSeconds: widget.durationSeconds,
          progress: _progress,
          timeLabel: '$minutes:$remain',
          playing: _playing,
          loading: false,
          onTap: () => unawaited(_toggle()),
        ),
        IconButton(
          onPressed: widget.onDelete,
          icon: Icon(
            Icons.close,
            size: 18,
            color: context.palette.secondaryText,
          ),
        ),
      ],
    );
  }
}
