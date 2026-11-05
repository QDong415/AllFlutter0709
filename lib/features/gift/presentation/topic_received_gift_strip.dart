import 'dart:async';

import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/features/gift/data/gift_list_errors.dart';
import 'package:all_flutter0709/features/gift/data/gift_model.dart';
import 'package:all_flutter0709/features/gift/data/gift_repository.dart';
import 'package:all_flutter0709/features/gift/presentation/gift_sender_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 动态详情里的「收到礼物」区块（独立 header，对齐 Android `feed_giftlist`）。
class TopicReceivedGiftStrip extends StatefulWidget {
  const TopicReceivedGiftStrip({super.key, required this.feedId});

  final String feedId;

  @override
  State<TopicReceivedGiftStrip> createState() => TopicReceivedGiftStripState();
}

class TopicReceivedGiftStripState extends State<TopicReceivedGiftStrip> {
  final GiftRepository _repository = const GiftRepository();
  List<ReceivedGift> _gifts = const <ReceivedGift>[];
  bool _loading = true;
  String? _errorText;
  bool _hiddenByPrivacy = false;
  int _loadSerial = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load(showPlaceholder: true));
  }

  @override
  void didUpdateWidget(covariant TopicReceivedGiftStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feedId != widget.feedId) {
      unawaited(_load(showPlaceholder: true));
    }
  }

  /// 送礼成功后由详情页调用：先本地合并，再静默对 `feed_giftlist`。
  void onGiftSent(GiftSendResult result) {
    if (!mounted) {
      return;
    }
    setState(() => _mergeSendResult(result));
    unawaited(_load(showPlaceholder: false));
  }

  void _mergeSendResult(GiftSendResult result) {
    final sent = result.giftModel;
    final addCount = result.count;
    final index = _gifts.indexWhere((g) => g.giftId == sent.giftId);
    if (index >= 0) {
      final old = _gifts[index];
      final next = List<ReceivedGift>.of(_gifts);
      next[index] = ReceivedGift(
        giftId: old.giftId,
        title: old.title.isNotEmpty ? old.title : sent.title,
        picture: old.picture.isNotEmpty ? old.picture : sent.picture,
        totalCount: old.totalCount + addCount,
        totalPrice: old.totalPrice + sent.price * addCount,
      );
      _gifts = next;
    } else {
      _gifts = [
        ReceivedGift(
          giftId: sent.giftId,
          title: sent.title,
          picture: sent.picture,
          totalCount: addCount,
          totalPrice: sent.price * addCount,
        ),
        ..._gifts,
      ];
    }
    _loading = false;
  }

  Future<void> _load({required bool showPlaceholder}) async {
    final feedId = widget.feedId.trim();
    if (feedId.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _gifts = const <ReceivedGift>[];
        });
      }
      return;
    }
    final serial = ++_loadSerial;
    if (showPlaceholder || _gifts.isEmpty) {
      setState(() => _loading = true);
    }
    try {
      final gifts = await _repository.fetchReceivedGifts(
        feedId: feedId,
        type: 1,
      );
      if (!mounted || serial != _loadSerial) {
        return;
      }
      setState(() {
        _gifts = gifts;
        _loading = false;
        _errorText = null;
        _hiddenByPrivacy = false;
      });
    } catch (error) {
      if (!mounted || serial != _loadSerial) {
        return;
      }
      setState(() {
        _loading = false;
        _hiddenByPrivacy = isGiftListHiddenError(error);
        _errorText = giftErrorMessage(error);
        if (_hiddenByPrivacy) {
          _gifts = const <ReceivedGift>[];
        }
      });
    }
  }

  int get _totalCount {
    var total = 0;
    for (final gift in _gifts) {
      total += gift.totalCount;
    }
    return total;
  }

  void _openSenders() {
    openGiftSenderPage(context, feedId: widget.feedId, type: 1);
  }

  @override
  Widget build(BuildContext context) {
    if (_gifts.isEmpty && _loading) {
      return const SizedBox.shrink();
    }
    if (_errorText != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.link,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '收到礼物',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF222222),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: const TextStyle(fontSize: 14, color: Color(0xFF8B8B90)),
              ),
            ],
          ),
        ),
      );
    }
    if (_gifts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.link,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    '收到礼物',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF222222),
                    ),
                  ),
                ),
                if (_totalCount > 0)
                  GestureDetector(
                    onTap: _openSenders,
                    child: Text(
                      '共 $_totalCount 个',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF8B8B90),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _gifts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final gift = _gifts[index];
                  return SizedBox(
                    width: 64,
                    child: Column(
                      children: [
                        Expanded(
                          child: gift.pictureUrl.isEmpty
                              ? const SizedBox.shrink()
                              : CachedNetworkImage(
                                  imageUrl: gift.pictureUrl,
                                  fit: BoxFit.contain,
                                  errorWidget: (_, _, _) =>
                                      const SizedBox.shrink(),
                                ),
                        ),
                        Text(
                          'x${gift.totalCount}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
