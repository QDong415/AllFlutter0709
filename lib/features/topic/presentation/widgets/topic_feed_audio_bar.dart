import 'dart:async';

import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/features/topic/data/models/topic_model.dart';
import 'package:all_flutter0709/features/topic/presentation/controllers/topic_audio_play_controller.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_audio_bar.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// 包住整张动态。卡片完全不可见，或所在页面 ticker 被关掉时，停止这条语音。
class TopicAudioVisibility extends ConsumerStatefulWidget {
  const TopicAudioVisibility({
    super.key,
    required this.playKey,
    required this.child,
  });

  final String playKey;
  final Widget child;

  @override
  ConsumerState<TopicAudioVisibility> createState() =>
      _TopicAudioVisibilityState();
}

class _TopicAudioVisibilityState extends ConsumerState<TopicAudioVisibility> {
  GoRouter? _router;
  bool? _tickersEnabled;
  bool _wasOnScreen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (!identical(router, _router)) {
      _router?.routerDelegate.removeListener(_onRoute);
      _router = router;
      _router?.routerDelegate.addListener(_onRoute);
    }
  }

  @override
  void dispose() {
    ref.read(topicAudioPlayControllerProvider).onHidden(widget.playKey);
    _router?.routerDelegate.removeListener(_onRoute);
    super.dispose();
  }

  void _handleVisibility(VisibilityInfo info) {
    if (info.visibleFraction > 0) {
      _wasOnScreen = true;
      return;
    }
    if (!_wasOnScreen) {
      return;
    }
    _wasOnScreen = false;
    ref.read(topicAudioPlayControllerProvider).onHidden(widget.playKey);
  }

  /// 路由变化时复用视频播放器的表面可见性判断。
  void _onRoute() {
    if (!_isSurfaceActive()) {
      ref.read(topicAudioPlayControllerProvider).onHidden(widget.playKey);
    }
  }

  /// 与动态视频一致：Shell 内仅 `/topic` 可播；根栈页面依赖 TickerMode。
  bool _isSurfaceActive() {
    if (!mounted) {
      return false;
    }
    final tickersEnabled =
        _tickersEnabled ?? TickerMode.valuesOf(context).enabled;
    if (!tickersEnabled) {
      return false;
    }
    final shell = StatefulNavigationShell.maybeOf(context);
    if (shell != null) {
      return GoRouter.of(context).state.matchedLocation == AppRoutes.topic;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final tickersEnabled = TickerMode.valuesOf(context).enabled;
    if (_tickersEnabled != tickersEnabled) {
      final previous = _tickersEnabled;
      _tickersEnabled = tickersEnabled;
      if (previous != null && !tickersEnabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          ref.read(topicAudioPlayControllerProvider).onHidden(widget.playKey);
        });
      }
    }
    return VisibilityDetector(
      key: Key('topic-audio-cell-${widget.playKey}'),
      onVisibilityChanged: _handleVisibility,
      child: widget.child,
    );
  }
}

/// 列表和详情共用的语音条，进度和播放状态来自全局播放器。
class TopicFeedAudioBar extends ConsumerWidget {
  const TopicFeedAudioBar({super.key, required this.topicModel});

  final TopicModel topicModel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(topicAudioPlayControllerProvider);
    final active = controller.targetPlayKey == topicModel.tid;
    final loading = active && controller.phase == TopicAudioPhase.loading;
    final playing = active && controller.phase == TopicAudioPhase.playing;
    final showProgress =
        active &&
        (controller.phase == TopicAudioPhase.playing ||
            controller.phase == TopicAudioPhase.paused);
    final seconds = showProgress
        ? controller.positionSeconds
        : topicModel.audioDurationSeconds;
    return TopicAudioBar(
      durationSeconds: topicModel.audioDurationSeconds,
      progress: showProgress ? controller.progress : 0,
      timeLabel: _formatClock(seconds),
      playing: playing,
      loading: loading,
      onTap: () {
        final before = controller.errorNonce;
        unawaited(_play(context, ref, before));
      },
    );
  }

  Future<void> _play(BuildContext context, WidgetRef ref, int before) async {
    await ref.read(topicAudioPlayControllerProvider).onTap(topicModel);
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
