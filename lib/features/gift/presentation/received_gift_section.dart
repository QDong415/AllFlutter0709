import 'dart:async';

import 'package:all_flutter0709/features/gift/data/gift_list_errors.dart';
import 'package:all_flutter0709/features/gift/data/gift_model.dart';
import 'package:all_flutter0709/features/gift/data/gift_repository.dart';
import 'package:all_flutter0709/features/gift/presentation/gift_sender_page.dart';
import 'package:all_flutter0709/features/gift/presentation/widgets/gift_user_avatar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 个人主页动态上方的礼物墙：收到的礼物网格，以及送礼靠前的人。
class ReceivedGiftSection extends StatefulWidget {
  const ReceivedGiftSection({super.key, required this.userId});

  final String userId;

  @override
  State<ReceivedGiftSection> createState() => ReceivedGiftSectionState();
}

class ReceivedGiftSectionState extends State<ReceivedGiftSection>
    with SingleTickerProviderStateMixin {
  static const _appearDuration = Duration(milliseconds: 320);

  final GiftRepository _repository = const GiftRepository();

  List<ReceivedGift> _gifts = const <ReceivedGift>[];
  List<TopSender> _senders = const <TopSender>[];
  bool _loading = false;
  int _loadSerial = 0;

  late final AnimationController _appearController;
  late final Animation<double> _appearCurve;

  @override
  void initState() {
    super.initState();
    _appearController = AnimationController(
      vsync: this,
      duration: _appearDuration,
    );
    _appearCurve = CurvedAnimation(
      parent: _appearController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    unawaited(_load(resetForNewUser: false));
  }

  @override
  void dispose() {
    _appearController.dispose();
    super.dispose();
  }

  void _syncAppearAnimation({required bool hasGifts, bool replay = false}) {
    if (!hasGifts) {
      _appearController.reset();
      return;
    }
    if (!replay && _appearController.status == AnimationStatus.completed) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _gifts.isEmpty) {
        return;
      }
      unawaited(_appearController.forward(from: 0));
    });
  }

  @override
  void didUpdateWidget(covariant ReceivedGiftSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      unawaited(_load(resetForNewUser: true));
    }
  }

  /// 下拉刷新等场景：静默重拉，有数据时保持展示直至新结果返回。
  void reloadSilently() {
    unawaited(_load(resetForNewUser: false));
  }

  Future<void> _load({required bool resetForNewUser}) async {
    final userId = widget.userId.trim();
    if (userId.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _gifts = const <ReceivedGift>[];
          _senders = const <TopSender>[];
        });
      }
      return;
    }
    final serial = ++_loadSerial;
    if (resetForNewUser) {
      _appearController.reset();
      setState(() {
        _loading = true;
        _gifts = const <ReceivedGift>[];
        _senders = const <TopSender>[];
      });
    } else if (_gifts.isEmpty) {
      setState(() => _loading = true);
    }
    try {
      final gifts = await _repository.fetchReceivedGifts(toUserId: userId);
      var senders = const <TopSender>[];
      try {
        senders = await _repository.fetchTopSenders(userId);
      } catch (error) {
        if (!isGiftListHiddenError(error)) {
          rethrow;
        }
      }
      if (!mounted || serial != _loadSerial) {
        return;
      }
      setState(() {
        _gifts = gifts;
        _senders = senders;
        _loading = false;
      });
      _syncAppearAnimation(hasGifts: gifts.isNotEmpty);
    } catch (_) {
      if (!mounted || serial != _loadSerial) {
        return;
      }
      _appearController.reset();
      setState(() {
        _loading = false;
        _gifts = const <ReceivedGift>[];
        _senders = const <TopSender>[];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_gifts.isEmpty && _appearController.value == 0) {
      return const SizedBox(width: double.infinity);
    }

    return AnimatedBuilder(
      animation: _appearCurve,
      builder: (context, child) {
        final t = _appearCurve.value;
        if (t <= 0 && _gifts.isEmpty) {
          return const SizedBox(width: double.infinity);
        }
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: t.clamp(0.001, 1),
            child: Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 6 * (1 - t)),
                child: child,
              ),
            ),
          ),
        );
      },
      child: _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '收到的礼物',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _gifts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 8,
                childAspectRatio: 0.62,
              ),
              itemBuilder: (context, index) {
                final gift = _gifts[index];
                return Column(
                  children: [
                    Expanded(
                      child: gift.pictureUrl.isEmpty
                          ? const SizedBox.shrink()
                          : CachedNetworkImage(
                              imageUrl: gift.pictureUrl,
                              fit: BoxFit.contain,
                              fadeInDuration: const Duration(milliseconds: 220),
                              fadeOutDuration: const Duration(milliseconds: 120),
                              placeholder: (_, _) => const ColoredBox(
                                color: Color(0xFFF3F3F5),
                              ),
                              errorWidget: (_, _, _) => const ColoredBox(
                                color: Color(0xFFF3F3F5),
                              ),
                            ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      gift.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF444444),
                      ),
                    ),
                    Text(
                      'x${gift.totalCount}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                );
              },
            ),
          if (!_loading) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => openGiftSenderPage(context, toUserId: widget.userId),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Text(
                      '送礼的人',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (_senders.isNotEmpty)
                      SizedBox(
                        height: 28,
                        width: _senders.length * 18.0 + 10,
                        child: Stack(
                          children: [
                            for (var i = 0; i < _senders.length; i++)
                              Positioned(
                                left: i * 18.0,
                                child: _SenderAvatar(url: _senders[i].avatarUrl),
                              ),
                          ],
                        ),
                      ),
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Color(0xFF8B8B90),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SenderAvatar extends StatelessWidget {
  const _SenderAvatar({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: GiftUserAvatar(url: url, size: 28),
    );
  }
}
