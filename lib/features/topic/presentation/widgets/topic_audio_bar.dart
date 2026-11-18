import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/app/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// 动态语音条：进度、时间、播放或暂停。下载中显示转圈。
class TopicAudioBar extends StatelessWidget {
  const TopicAudioBar({
    super.key,
    required this.durationSeconds,
    required this.progress,
    required this.timeLabel,
    required this.playing,
    required this.loading,
    required this.onTap,
  });

  final int durationSeconds;
  final double progress;
  final String timeLabel;
  final bool playing;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final width = (108.0 + durationSeconds * 2.2).clamp(128.0, 236.0);
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: width,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: palette.pressed,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: loading
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 20,
                        color: palette.titleText,
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    height: 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: palette.divider),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: const ColoredBox(color: AppColors.link),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: palette.bodyText,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
