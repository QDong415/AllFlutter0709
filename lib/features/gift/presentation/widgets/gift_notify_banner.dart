import 'dart:async';

import 'package:all_flutter0709/features/gift/data/gift_model.dart';
import 'package:all_flutter0709/features/gift/data/gift_repository.dart';
import 'package:all_flutter0709/features/gift/presentation/widgets/gift_user_avatar.dart';
import 'package:all_flutter0709/features/user/presentation/helpers/user_detail_navigation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const _pollIntervalSeconds = 15;
const _pollInterval = Duration(seconds: _pollIntervalSeconds);
const _initialPollDelaySeconds = 1;
const _initialPollDelay = Duration(seconds: _initialPollDelaySeconds);
const _showDuration = Duration(milliseconds: 3200);
const _maxPending = 5;

const _maleBackground = Color(0xFFD9EDF7);
const _maleName = Color(0xFF245269);
const _femaleBackground = Color(0xFFF2DEDE);
const _femaleName = Color(0xFF843534);

/// MainTab 根页面顶栏下方的送礼飘窗。
///
/// MainTab 首帧完成 1 秒后才允许首次轮询，避免与启动渲染争抢资源。
/// 仅在本页 ticker 开启且应用在前台时，按 [_pollInterval] 拉 `gift/notitylist`。
/// 被二级页面盖住或进入后台时停掉，并把当前这条放回队列。
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
  bool _tickerEnabled = false;
  bool _foreground = true;
  bool _active = false;
  bool _pollInFlight = false;
  bool _initialPollReady = false;
  DateTime? _lastPollStartedAt;

  void _log(String message) {
    debugPrint('[GiftNotify] $message');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _log('init observer');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _log('MainTab 首帧完成，${_initialPollDelay.inSeconds}s 后允许首次轮询');
      _initialPollTimer = Timer(_initialPollDelay, () {
        _initialPollTimer = null;
        if (!mounted) {
          return;
        }
        _initialPollReady = true;
        _log('首次轮询延时结束');
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
    _log('tickerEnabled $enabled -> enabled (二级页盖住时多为 false)');
    _tickerEnabled = enabled;
    _applyActive();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground =
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
    _log(
      'lifecycle=$state treatAsForeground=$foreground '
      'previousForeground=$_foreground',
    );
    if (foreground == _foreground) {
      return;
    }
    _foreground = foreground;
    _applyActive();
  }

  @override
  void dispose() {
    _log('dispose');
    _active = false;
    WidgetsBinding.instance.removeObserver(this);
    _initialPollTimer?.cancel();
    _pollTimer?.cancel();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _applyActive() {
    final next = _initialPollReady && _tickerEnabled && _foreground;
    if (next == _active) {
      return;
    }
    final wasActive = _active;
    _active = next;
    _log(
      'active $wasActive -> $_active '
      '(initialReady=$_initialPollReady '
      'ticker=$_tickerEnabled foreground=$_foreground)',
    );
    _pollTimer?.cancel();
    _pollTimer = null;
    _cancelHold();
    if (!_active && _showingModel != null) {
      _log('暂停，当前飘窗 id=${_showingModel!.id} 放回队列');
      _pendingModelList.insert(0, _showingModel!);
      _showingModel = null;
      _sortPending();
    }
    if (_active) {
      _log('恢复轮询，最小间隔 ${_pollInterval.inSeconds}s');
      _scheduleNextPoll();
    } else {
      _log('停止轮询定时器');
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
      _log('轮询已到期，立即请求');
      unawaited(_poll());
      return;
    }
    _log(
      '距上次请求不足 ${_pollInterval.inSeconds}s，'
      '${delay.inMilliseconds}ms 后再请求',
    );
    _pollTimer = Timer(delay, () {
      _pollTimer = null;
      unawaited(_poll());
    });
  }

  Future<void> _poll() async {
    if (!mounted || !_active) {
      _log('poll 跳过：mounted=$mounted active=$_active');
      return;
    }
    if (_pollInFlight) {
      _log('poll 跳过：上一轮尚未结束');
      return;
    }
    _pollInFlight = true;
    _lastPollStartedAt = DateTime.now();
    final firstIdLabel = _firstId?.toString() ?? 'null(最近2分钟)';
    _log(
      'poll 发起 GET gift/notitylist firstid=$firstIdLabel '
      'at=${_lastPollStartedAt!.toIso8601String()}',
    );
    try {
      final notifyModelList = await _repository.fetchNotifyList(
        firstId: _firstId,
      );
      if (!mounted) {
        _log('poll 返回后 widget 已卸载');
        return;
      }
      _log(
        'poll 成功 count=${notifyModelList.length} '
        'ids=${notifyModelList.map((e) => e.id).join(",")}',
      );
      _enqueue(notifyModelList);
      if (_active) {
        _pump();
      } else {
        _log('poll 成功但已 inactive，不入队播放');
      }
    } catch (error, stackTrace) {
      _log('poll 失败: $error');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace, label: '[GiftNotify]');
      }
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
      _firstId = maxId;
    }
    _sortPending();
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
    setState(() => _showingModel = notifyModel);
    _holdTimer = Timer(_showDuration, () {
      if (!mounted || token != _showToken) {
        return;
      }
      _showingModel = null;
      _pump(rebuildIfIdle: true);
    });
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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1.1),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: notifyModel == null
          ? const SizedBox.shrink(key: ValueKey<String>('gift-notify-empty'))
          : _GiftNotifyCard(
              key: ValueKey<int>(notifyModel.id),
              notifyModel: notifyModel,
              onTap: () => _openReceiver(notifyModel),
            ),
    );
  }
}

/// 一条飘窗：收礼人头像、文案、礼物图和数量。
class _GiftNotifyCard extends StatelessWidget {
  const _GiftNotifyCard({
    super.key,
    required this.notifyModel,
    required this.onTap,
  });

  final GiftNotifyModel notifyModel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final male = notifyModel.receiverIsMale;
    final background = male ? _maleBackground : _femaleBackground;
    final nameColor = male ? _maleName : _femaleName;
    final toName = notifyModel.toName;
    final senderName = notifyModel.senderName;
    final span = TextSpan(
      style: const TextStyle(
        fontSize: 14,
        height: 1.25,
        color: Color(0xFF222222),
      ),
      children: [
        TextSpan(
          text: toName,
          style: TextStyle(color: nameColor, fontWeight: FontWeight.w600),
        ),
        const TextSpan(text: ' 收到 '),
        TextSpan(
          text: senderName,
          style: TextStyle(color: nameColor, fontWeight: FontWeight.w600),
        ),
        TextSpan(text: ' 的${notifyModel.title}'),
      ],
    );

    return Material(
      color: background,
      elevation: 6,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: [
              GiftUserAvatar(url: notifyModel.toAvatarUrl, size: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  span,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _GiftThumb(url: notifyModel.pictureUrl),
              const SizedBox(width: 6),
              Text(
                'x ${notifyModel.count}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: nameColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 飘窗右侧的礼物图。
class _GiftThumb extends StatelessWidget {
  const _GiftThumb({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: url.isEmpty
          ? const SizedBox.shrink()
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              errorWidget: (_, _, _) => const SizedBox.shrink(),
            ),
    );
  }
}
