import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 视频详情页自定义播放控件（进度 / 播放暂停 / 静音）
class VideoDetailPlayerControls extends StatelessWidget {
  const VideoDetailPlayerControls({
    super.key,
    required this.controller,
    required this.onBackgroundTap,
    required this.onBackgroundDoubleTap,
    required this.onPlayPause,
    required this.onToggleMute,
  });

  final VideoPlayerController controller;
  final VoidCallback onBackgroundTap;
  final VoidCallback onBackgroundDoubleTap;
  final VoidCallback onPlayPause;
  final VoidCallback onToggleMute;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final value = controller.value;
        final duration = value.duration;
        final position = value.position;
        final maxMs = duration.inMilliseconds;
        final posMs = position.inMilliseconds.clamp(0, maxMs > 0 ? maxMs : 0);
        final progress = maxMs <= 0 ? 0.0 : posMs / maxMs;

        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBackgroundTap,
              onDoubleTap: onBackgroundDoubleTap,
              child: const ColoredBox(color: Color(0x26000000)),
            ),
            Center(
              child: IconButton(
                onPressed: onPlayPause,
                iconSize: 56,
                color: Colors.white,
                icon: Icon(
                  value.isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_filled_rounded,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 8, 10),
                child: Row(
                  children: [
                    Text(
                      _formatDuration(position),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white38,
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: progress.clamp(0.0, 1.0),
                          onChanged: maxMs <= 0
                              ? null
                              : (next) {
                                  controller.seekTo(
                                    Duration(
                                      milliseconds: (next * maxMs).round(),
                                    ),
                                  );
                                },
                        ),
                      ),
                    ),
                    Text(
                      _formatDuration(duration),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    IconButton(
                      onPressed: onToggleMute,
                      color: Colors.white,
                      icon: Icon(
                        value.volume <= 0
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
