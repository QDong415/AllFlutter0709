import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// 列表滚动时立即刷新 [VisibilityDetector]，减少「已滑出仍不回调」的漏检。
class TopicAudioListScrollNotify extends StatelessWidget {
  const TopicAudioListScrollNotify({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollUpdateNotification ||
            notification is ScrollEndNotification) {
          VisibilityDetectorController.instance.notifyNow();
        }
        return false;
      },
      child: child,
    );
  }
}