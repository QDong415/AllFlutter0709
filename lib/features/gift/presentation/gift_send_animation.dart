import 'dart:async';

import 'package:all_flutter0709/features/gift/presentation/gift_count_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

_GiftFxDriver? _driver;

/// 在页面上播放送礼动画。
///
/// 对齐 Buddy `GiftAnimator`：礼物图同一时间只保留最新一张（连点时会立刻去掉上一张，
/// 避免多层同时放大消失）；右侧数量会被换掉并重新放大。
Future<void> playGiftSendAnimation(
  BuildContext context, {
  required String pictureUrl,
  required int count,
}) async {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    return;
  }
  if (pictureUrl.isNotEmpty) {
    try {
      await precacheImage(CachedNetworkImageProvider(pictureUrl), context);
    } catch (_) {}
  }
  final driver = _driver ??= _GiftFxDriver();
  driver.play(overlay, pictureUrl: pictureUrl, count: count);
}

class _GiftHit {
  const _GiftHit({required this.pictureUrl, required this.count});

  final String pictureUrl;
  final int count;
}

class _GiftFxDriver {
  OverlayEntry? entry;
  _GiftSendLayerState? state;
  final List<_GiftHit> queue = [];

  void play(
    OverlayState overlay, {
    required String pictureUrl,
    required int count,
  }) {
    queue.add(_GiftHit(pictureUrl: pictureUrl, count: count));
    if (entry == null) {
      entry = OverlayEntry(builder: (context) => _GiftSendLayer(driver: this));
      overlay.insert(entry!);
      return;
    }
    state?.consume();
  }

  void close() {
    final current = entry;
    entry = null;
    state = null;
    if (_driver == this) {
      _driver = null;
    }
    current?.remove();
  }
}

class _FlyingGift {
  _FlyingGift({required this.pictureUrl, required this.controller});

  final String pictureUrl;
  final AnimationController controller;
}

/// 礼物图缩放、上飘；数量单独重播。
class _GiftSendLayer extends StatefulWidget {
  const _GiftSendLayer({required this.driver});

  final _GiftFxDriver driver;

  @override
  State<_GiftSendLayer> createState() => _GiftSendLayerState();
}

class _GiftSendLayerState extends State<_GiftSendLayer>
    with TickerProviderStateMixin {
  /// 入场约 150ms 半透明淡入，停到 1200ms，离场最长到 2000ms。
  static const _imageDuration = Duration(milliseconds: 2000);
  static const _badgeDuration = Duration(milliseconds: 1300);

  _FlyingGift? _currentImage;
  AnimationController? _badgeController;
  int _badgeToken = 0;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    widget.driver.state = this;
    consume(notify: false);
  }

  void consume({bool notify = true}) {
    final hits = List<_GiftHit>.of(widget.driver.queue);
    widget.driver.queue.clear();
    if (hits.isEmpty) {
      return;
    }
    for (final hit in hits) {
      _spawnImage(hit.pictureUrl);
    }
    _restartBadge(hits.last.count);
    if (notify && mounted) {
      setState(() {});
    }
  }

  void _spawnImage(String pictureUrl) {
    _dismissCurrentImage(notify: false);
    final controller = AnimationController(
      vsync: this,
      duration: _imageDuration,
    );
    final flying = _FlyingGift(pictureUrl: pictureUrl, controller: controller);
    _currentImage = flying;
    controller.forward().whenComplete(() {
      if (!mounted || !controller.isCompleted) {
        return;
      }
      if (_currentImage?.controller != controller) {
        return;
      }
      _currentImage = null;
      final done = _badgeController == null;
      if (!done) {
        setState(() {});
      }
      controller.dispose();
      if (done) {
        widget.driver.close();
      }
    });
  }

  /// 连点换新礼物时立刻去掉上一张，不播离场放大（与 Android 叠层观感一致）。
  void _dismissCurrentImage({bool notify = true}) {
    final flying = _currentImage;
    if (flying == null) {
      return;
    }
    _currentImage = null;
    flying.controller.dispose();
    if (notify && mounted) {
      setState(() {});
    }
  }

  void _restartBadge(int count) {
    final previous = _badgeController;
    _badgeToken++;
    final token = _badgeToken;
    final controller = AnimationController(
      vsync: this,
      duration: _badgeDuration,
    );
    _badgeController = controller;
    _count = count;
    previous?.dispose();
    controller.forward().whenComplete(() {
      if (!mounted || token != _badgeToken || !controller.isCompleted) {
        return;
      }
      _badgeController = null;
      final done = _currentImage == null;
      if (!done) {
        setState(() {});
      }
      controller.dispose();
      if (done) {
        widget.driver.close();
      }
    });
  }

  @override
  void dispose() {
    _dismissCurrentImage(notify: false);
    _badgeController?.dispose();
    if (widget.driver.state == this) {
      widget.driver.state = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final imageSize = width / 2;
    final left = width / 6;
    final top = width / 4;
    final badge = _badgeController;

    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (_currentImage case final image?)
              Positioned(
                left: left,
                top: top,
                width: imageSize,
                height: imageSize,
                child: AnimatedBuilder(
                  animation: image.controller,
                  builder: (context, child) {
                    final ms =
                        image.controller.value * _imageDuration.inMilliseconds;
                    return Transform.scale(
                      alignment: Alignment.center,
                      scale: _imageScale(ms),
                      child: Opacity(opacity: _imageOpacity(ms), child: child),
                    );
                  },
                  child: Center(child: _giftImage(image.pictureUrl)),
                ),
              ),
            if (badge != null)
              Positioned(
                left: left + imageSize,
                top: top + imageSize - 40,
                child: AnimatedBuilder(
                  animation: badge,
                  builder: (context, child) {
                    return Transform.scale(
                      alignment: Alignment.centerLeft,
                      scale: _countScale(badge.value),
                      child: child,
                    );
                  },
                  child: GiftCountBadge(count: _count),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _giftImage(String pictureUrl) {
    if (pictureUrl.isEmpty) {
      return const Icon(
        Icons.card_giftcard,
        size: 72,
        color: Color(0xFFE85D75),
      );
    }
    return CachedNetworkImage(
      imageUrl: pictureUrl,
      fit: BoxFit.contain,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      errorWidget: (context, url, error) =>
          const Icon(Icons.card_giftcard, size: 72, color: Color(0xFFE85D75)),
    );
  }

  static const _entryFadeMs = 150.0;

  double _imageScale(double ms) {
    if (ms < 1200) {
      return 1;
    }
    return _lerp(1, 1.3, ((ms - 1200) / 700).clamp(0, 1));
  }

  double _imageOpacity(double ms) {
    if (ms < _entryFadeMs) {
      return _lerp(0.5, 1, ms / _entryFadeMs);
    }
    if (ms < 1200) {
      return 1;
    }
    return (1 - (ms - 1200) / 300).clamp(0, 1);
  }

  double _countScale(double t) {
    return _lerp(1.6, 1, _overshoot.transform(t));
  }

  double _lerp(double from, double to, double t) => from + (to - from) * t;
}

/// Android `OvershootInterpolator`，默认 tension = 2。
const Curve _overshoot = _OvershootCurve();

class _OvershootCurve extends Curve {
  const _OvershootCurve();

  @override
  double transformInternal(double t) {
    const tension = 2.0;
    t -= 1.0;
    return t * t * ((tension + 1) * t + tension) + 1.0;
  }
}
