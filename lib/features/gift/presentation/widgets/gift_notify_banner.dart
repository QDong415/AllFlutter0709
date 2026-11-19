import 'dart:async';
import 'dart:math' as math;

import 'package:all_flutter0709/features/gift/data/gift_model.dart';
import 'package:all_flutter0709/features/gift/data/gift_repository.dart';
import 'package:all_flutter0709/features/gift/presentation/widgets/gift_user_avatar.dart';
import 'package:all_flutter0709/features/user/presentation/helpers/user_detail_navigation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pollIntervalSeconds = 30;
const _pollInterval = Duration(seconds: _pollIntervalSeconds);
const _initialPollDelaySeconds = 1;
const _initialPollDelay = Duration(seconds: _initialPollDelaySeconds);
const _showDuration = Duration(milliseconds: 5500);
const _maxPending = 5;
const _cursorKey = 'gift_notify_first_id';

const _maleBackground = Color(0xFFD9EDF7);
const _maleName = Color(0xFF245269);
const _femaleBackground = Color(0xFFF2DEDE);
const _femaleName = Color(0xFF843534);

/// MainTab 根页面顶栏下方的送礼飘窗。
///
/// MainTab 首帧完成 1 秒后才允许首次轮询，避免与启动渲染争抢资源。
/// 仅在本页 ticker 开启且应用在前台时，按 [_pollInterval] 拉 `gift/notitylist`。
/// 被二级页面盖住或进入后台时停掉，当前正在播的那条直接结束。
/// 见过的最大礼物 id 存在本机，冷启动从这条之后继续拉。
class GiftNotifyBanner extends StatefulWidget {
  const GiftNotifyBanner({super.key});

  @override
  State<GiftNotifyBanner> createState() => _GiftNotifyBannerState();
}

class _GiftNotifyBannerState extends State<GiftNotifyBanner>
    with WidgetsBindingObserver {
  final GiftRepository _repository = const GiftRepository();
  final List<GiftNotifyModel> _pendingModelList = <GiftNotifyModel>[];

  Timer? _initialPollTimer;
  Timer? _pollTimer;
  Timer? _holdTimer;
  GiftNotifyModel? _showingModel;
  int? _firstId;
  int _showToken = 0;
  int _showingToken = 0;
  bool _leaving = false;
  bool _tickerEnabled = false;
  bool _foreground = true;
  bool _active = false;
  bool _pollInFlight = false;
  bool _initialPollReady = false;
  bool _cursorReady = false;
  DateTime? _lastPollStartedAt;
  Future<void> _cursorWriteQueue = Future<void>.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadCursor());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _initialPollTimer = Timer(_initialPollDelay, () {
        _initialPollTimer = null;
        if (!mounted) {
          return;
        }
        _initialPollReady = true;
        _applyActive();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled = TickerMode.valuesOf(context).enabled;
    if (enabled == _tickerEnabled) {
      return;
    }
    _tickerEnabled = enabled;
    _applyActive();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground =
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
    if (foreground == _foreground) {
      return;
    }
    _foreground = foreground;
    _applyActive();
  }

  @override
  void dispose() {
    _active = false;
    WidgetsBinding.instance.removeObserver(this);
    _initialPollTimer?.cancel();
    _pollTimer?.cancel();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _applyActive() {
    final next =
        _initialPollReady && _cursorReady && _tickerEnabled && _foreground;
    if (next == _active) {
      return;
    }
    _active = next;
    _pollTimer?.cancel();
    _pollTimer = null;
    _cancelHold();
    if (!_active && _showingModel != null) {
      _showingModel = null;
      _leaving = false;
    }
    if (_active) {
      _scheduleNextPoll();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_active) {
        _pump();
      } else {
        setState(() {});
      }
    });
  }

  void _scheduleNextPoll() {
    if (!mounted || !_active) {
      return;
    }
    _pollTimer?.cancel();

    final now = DateTime.now();
    final lastPollStartedAt = _lastPollStartedAt;
    var delay = Duration.zero;
    if (lastPollStartedAt != null) {
      final elapsed = now.difference(lastPollStartedAt);
      if (elapsed.isNegative) {
        // 系统时间回拨时最多等待一个完整周期，避免定时器被卡很久。
        delay = _pollInterval;
      } else if (elapsed < _pollInterval) {
        delay = _pollInterval - elapsed;
      }
    }

    if (delay == Duration.zero) {
      unawaited(_poll());
      return;
    }
    _pollTimer = Timer(delay, () {
      _pollTimer = null;
      unawaited(_poll());
    });
  }

  Future<void> _poll() async {
    if (!mounted || !_active) {
      return;
    }
    if (_pollInFlight) {
      return;
    }
    _pollInFlight = true;
    _lastPollStartedAt = DateTime.now();
    try {
      final notifyModelList = await _repository.fetchNotifyList(
        firstId: _firstId,
      );
      if (!mounted) {
        return;
      }
      _enqueue(notifyModelList);
      if (_active) {
        _pump();
      }
    } catch (_) {
      // 轮询失败时保持已有队列与游标，等待下一轮。
    } finally {
      _pollInFlight = false;
      if (mounted && _active) {
        _scheduleNextPoll();
      }
    }
  }

  void _enqueue(List<GiftNotifyModel> notifyModelList) {
    var maxId = _firstId ?? 0;
    for (final notifyModel in notifyModelList) {
      if (notifyModel.id > maxId) {
        maxId = notifyModel.id;
      }
      if (notifyModel.id <= 0) {
        continue;
      }
      if (_firstId != null && notifyModel.id <= _firstId!) {
        continue;
      }
      if (_showingModel?.id == notifyModel.id) {
        continue;
      }
      final alreadyPending = _pendingModelList.any(
        (item) => item.id == notifyModel.id,
      );
      if (alreadyPending) {
        continue;
      }
      _pendingModelList.add(notifyModel);
    }
    if (maxId > (_firstId ?? 0)) {
      _rememberCursor(maxId);
    }
    _sortPending();
  }

  /// 读本机游标。读完之前不发请求，避免冷启动先按「最近 5 分钟」把旧礼物再拉一次。
  Future<void> _loadCursor() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getInt(_cursorKey) ?? 0;
      if (stored > (_firstId ?? 0)) {
        _firstId = stored;
      }
    } catch (_) {
    } finally {
      _cursorReady = true;
      if (mounted) {
        _applyActive();
      }
    }
  }

  void _rememberCursor(int firstId) {
    if (firstId <= (_firstId ?? 0)) {
      return;
    }
    _firstId = firstId;
    _cursorWriteQueue = _cursorWriteQueue.then((_) => _writeCursor());
  }

  Future<void> _writeCursor() async {
    final firstId = _firstId;
    if (firstId == null || firstId <= 0) {
      return;
    }
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getInt(_cursorKey) ?? 0;
      if (firstId <= stored) {
        return;
      }
      await preferences.setInt(_cursorKey, firstId);
    } catch (_) {}
  }

  void _sortPending() {
    _pendingModelList.sort((a, b) => b.id.compareTo(a.id));
    if (_pendingModelList.length <= _maxPending) {
      return;
    }
    _pendingModelList.removeRange(_maxPending, _pendingModelList.length);
  }

  void _pump({bool rebuildIfIdle = false}) {
    if (!_active || _showingModel != null) {
      return;
    }
    if (_pendingModelList.isEmpty) {
      if (rebuildIfIdle) {
        setState(() {});
      }
      return;
    }
    final notifyModel = _pendingModelList.removeAt(0);
    final token = ++_showToken;
    setState(() {
      _showingModel = notifyModel;
      _showingToken = token;
      _leaving = false;
    });
    _holdTimer = Timer(_showDuration, () {
      if (!mounted || token != _showToken) {
        return;
      }
      setState(() => _leaving = true);
    });
  }

  void _finishShowing() {
    if (!mounted || _showingToken != _showToken) {
      return;
    }
    setState(() {
      _showingModel = null;
      _leaving = false;
    });
    _pump(rebuildIfIdle: true);
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _showToken++;
  }

  void _openReceiver(GiftNotifyModel notifyModel) {
    openUserDetailPage(
      context,
      userId: notifyModel.toUserId,
      name: notifyModel.toName,
      avatar: notifyModel.toAvatar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifyModel = _showingModel;
    if (notifyModel == null) {
      return const SizedBox.shrink();
    }
    return _GiftNotifyCard(
      key: ValueKey<int>(notifyModel.id),
      notifyModel: notifyModel,
      leaving: _leaving,
      onTap: () => _openReceiver(notifyModel),
      onDismissed: _finishShowing,
    );
  }
}

/// 一条飘窗：条带文案 + 右侧礼物略高出条带，停留时缓动浮动。
class _GiftNotifyCard extends StatefulWidget {
  const _GiftNotifyCard({
    super.key,
    required this.notifyModel,
    required this.leaving,
    required this.onTap,
    required this.onDismissed,
  });

  final GiftNotifyModel notifyModel;
  final bool leaving;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  @override
  State<_GiftNotifyCard> createState() => _GiftNotifyCardState();
}

class _GiftNotifyCardState extends State<_GiftNotifyCard>
    with TickerProviderStateMixin {
  static const _cardHeight = 92.0;
  static const _barHeight = 52.0;

  /// 礼物图布局宽高固定，蓝条按它的中心对齐。
  static const _giftSize = 88.0;
  static const _giftTop = (_cardHeight - _giftSize) / 2;
  static const _barTop = _giftTop + (_giftSize - _barHeight) / 2;

  /// 上下浮动留在组件高度内部，避免画到外面被父级裁掉。
  static const _floatDistance = 8.0;
  static const _restTop = 16.0;

  late final AnimationController _presenceController;
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _presenceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 360),
    )..forward();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _presenceController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _floatController.repeat();
      } else if (status == AnimationStatus.dismissed && widget.leaving) {
        widget.onDismissed();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _GiftNotifyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.leaving && !oldWidget.leaving) {
      _floatController.stop();
      _presenceController.reverse();
    }
  }

  @override
  void dispose() {
    _presenceController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifyModel = widget.notifyModel;
    final male = notifyModel.receiverIsMale;
    final barColor = male ? _maleBackground : _femaleBackground;
    final accent = male ? _maleName : _femaleName;
    final toName = notifyModel.toName;
    final senderName = notifyModel.senderName;
    const radius = BorderRadius.all(Radius.circular(26));
    const barShadow = [
      BoxShadow(
        color: Color(0x28000000),
        blurRadius: 16,
        offset: Offset(0, 6),
        spreadRadius: -4,
      ),
      BoxShadow(color: Color(0x14000000), blurRadius: 5, offset: Offset(0, 2)),
    ];

    final textSpan = TextSpan(
      style: const TextStyle(
        fontSize: 16,
        height: 1.25,
        color: Color(0xFF1F1F1F),
      ),
      children: [
        TextSpan(
          text: toName,
          style: TextStyle(color: accent, fontWeight: FontWeight.w700),
        ),
        const TextSpan(text: ' 收到 '),
        TextSpan(
          text: senderName,
          style: TextStyle(color: accent, fontWeight: FontWeight.w700),
        ),
        TextSpan(text: ' 的${notifyModel.title}'),
      ],
    );

    final card = AnimatedBuilder(
      animation: Listenable.merge([_presenceController, _floatController]),
      builder: (context, child) {
        final entering = !widget.leaving;
        final progress = entering
            ? Curves.easeOutCubic.transform(_presenceController.value)
            : Curves.easeInCubic.transform(_presenceController.value);
        final opacity = entering ? 0.6 + 0.4 * progress : progress;
        final bob =
            math.sin(_floatController.value * math.pi * 2) * _floatDistance;
        final top = entering
            ? _restTop * progress + (_presenceController.isCompleted ? bob : 0)
            : _restTop - (_cardHeight + _restTop) * (1 - progress);
        return SizedBox(
          height: _cardHeight + _restTop * 2,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: top,
                height: _cardHeight,
                child: Opacity(opacity: opacity, child: child),
              ),
            ],
          ),
        );
      },
      child: SizedBox(
        height: _cardHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 0,
              right: _giftSize * 0.5,
              top: _barTop,
              height: _barHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      barColor,
                      Color.lerp(barColor, Colors.white, 0.32)!,
                    ],
                  ),
                  border: Border.all(color: const Color(0x18000000)),
                  boxShadow: barShadow,
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: radius,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: radius,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accent.withValues(alpha: 0.35),
                                width: 1.5,
                              ),
                            ),
                            child: GiftUserAvatar(
                              url: notifyModel.toAvatarUrl,
                              size: 36,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(
                              textSpan,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -2,
              top: _giftTop,
              child: _GiftNotifyHero(
                pictureUrl: notifyModel.pictureUrl,
                count: notifyModel.count,
                accent: accent,
                onTap: widget.onTap,
              ),
            ),
          ],
        ),
      ),
    );
    return card;
  }
}

/// 飘窗右侧礼物：尺寸大于条带，带光晕与数量角标。
class _GiftNotifyHero extends StatelessWidget {
  const _GiftNotifyHero({
    required this.pictureUrl,
    required this.count,
    required this.accent,
    required this.onTap,
  });

  final String pictureUrl;
  final int count;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const size = 88.0;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: SizedBox(
        width: size + 8,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: size * 0.82,
              height: size * 0.82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.24),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
            if (pictureUrl.isNotEmpty)
              Transform.scale(
                scale: 1.12,
                child: CachedNetworkImage(
                  imageUrl: pictureUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            Positioned(
              right: 0,
              bottom: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  child: Text(
                    'x$count',
                    style: TextStyle(
                      inherit: false,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      height: 1.05,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
