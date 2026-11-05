import 'dart:async';

import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/features/gift/data/gift_model.dart';
import 'package:all_flutter0709/features/gift/data/gift_repository.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

/// Buddy 送礼数量档位。点一次「发送」就按这个数量计一次连击。
const giftCountOptions = <int>[1, 10, 66, 100, 188, 520, 1314];

/// 打开送礼面板。面板保持打开，可连点。
///
/// [onCombo] 每次点击立刻回调，用来播动画，数量是这一轮连击的累计。
/// [onSent] 停手约 1 秒后服务端扣款成功才回调一次。
/// [type] 1 为动态，4 为聊天。动态需要带上 [feedId]。
Future<void> showGiftSheet(
  BuildContext context, {
  required String toUserId,
  required int type,
  String feedId = '0',
  void Function(GiftModel giftModel, int count)? onCombo,
  void Function(GiftSendResult result)? onSent,
}) {
  return showMaterialModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return GiftSheet(
        toUserId: toUserId,
        type: type,
        feedId: feedId,
        onCombo: onCombo,
        onSent: onSent,
      );
    },
  );
}

/// 礼物选择和确认送礼。
class GiftSheet extends ConsumerStatefulWidget {
  const GiftSheet({
    super.key,
    required this.toUserId,
    required this.type,
    required this.feedId,
    this.onCombo,
    this.onSent,
  });

  final String toUserId;
  final int type;
  final String feedId;
  final void Function(GiftModel giftModel, int count)? onCombo;
  final void Function(GiftSendResult result)? onSent;

  @override
  ConsumerState<GiftSheet> createState() => _GiftSheetState();
}

class _GiftSheetState extends ConsumerState<GiftSheet> {
  final GiftRepository _repository = const GiftRepository();
  List<GiftModel> _giftModelList = const [];
  int? _selectedGiftId;
  int _count = 1;
  int _coin = 0;
  bool _loading = true;
  String _errorText = '';
  Timer? _comboTimer;
  int _hits = 0;
  int _pendingSpent = 0;
  GiftModel? _comboGiftModel;
  int _comboUnitCount = 1;

  @override
  void initState() {
    super.initState();
    _coin = ref.read(accountProvider)?.coin ?? 0;
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<Object>([
        _repository.fetchGiftList(),
        _repository.fetchCoin(),
      ]);
      if (!mounted) {
        return;
      }
      final giftModelList = results[0] as List<GiftModel>;
      setState(() {
        _giftModelList = giftModelList;
        _coin = results[1] as int;
        _selectedGiftId = giftModelList.isEmpty
            ? null
            : giftModelList.first.giftId;
        _loading = false;
        _errorText = '';
      });
      _storeCoin(_coin);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorText = _messageOf(error);
      });
    }
  }

  GiftModel? get _selected {
    for (final giftModel in _giftModelList) {
      if (giftModel.giftId == _selectedGiftId) {
        return giftModel;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _comboTimer?.cancel();
    final pending = _takeCombo();
    if (pending != null) {
      unawaited(_submitCombo(pending));
    }
    super.dispose();
  }

  /// 连点「发送」。先播动画并本地扣金币，停 1 秒再把累计数量交给服务端。
  void _send() {
    final giftModel = _selected;
    if (giftModel == null) {
      return;
    }
    final cost = giftModel.price * _count;
    if (_coin < cost) {
      AppToast.show(context, '余额不足');
      return;
    }
    if (_comboGiftModel != null &&
        _comboGiftModel!.giftId != giftModel.giftId) {
      final pending = _takeCombo();
      if (pending != null) {
        unawaited(_submitCombo(pending));
      }
    }
    _comboGiftModel = giftModel;
    _comboUnitCount = _count;
    _hits += 1;
    _pendingSpent += cost;
    final totalCount = _hits * _comboUnitCount;
    setState(() => _coin -= cost);
    _storeCoin(_coin);
    widget.onCombo?.call(giftModel, totalCount);
    _comboTimer?.cancel();
    _comboTimer = Timer(const Duration(seconds: 1), () {
      final pending = _takeCombo();
      if (pending != null) {
        unawaited(_submitCombo(pending));
      }
    });
  }

  _PendingCombo? _takeCombo() {
    _comboTimer?.cancel();
    _comboTimer = null;
    final giftModel = _comboGiftModel;
    if (giftModel == null || _hits < 1) {
      return null;
    }
    final pending = _PendingCombo(
      giftModel: giftModel,
      count: _hits * _comboUnitCount,
      spent: _pendingSpent,
    );
    _hits = 0;
    _comboGiftModel = null;
    _pendingSpent = 0;
    return pending;
  }

  Future<void> _submitCombo(_PendingCombo pending) async {
    final notifier = ref.read(accountProvider.notifier);
    final account = ref.read(accountProvider);
    final toUserId = widget.toUserId;
    final type = widget.type;
    final feedId = widget.feedId;
    final onSent = widget.onSent;
    try {
      final coin = await _repository.send(
        toUserId: toUserId,
        giftId: pending.giftModel.giftId,
        count: pending.count,
        type: type,
        feedId: feedId,
      );
      final displayCoin = coin - _pendingSpent;
      if (mounted) {
        _storeCoin(displayCoin);
        setState(() => _coin = displayCoin);
      } else if (account != null) {
        await notifier.setAccount(account.copyWith(coin: coin));
      }
      onSent?.call(
        GiftSendResult(
          giftModel: pending.giftModel,
          count: pending.count,
          coin: displayCoin,
        ),
      );
    } catch (error) {
      final restored = (account?.coin ?? _coin) + pending.spent;
      if (mounted) {
        _coin = restored;
        _storeCoin(_coin);
        setState(() {});
        AppToast.show(context, _messageOf(error));
      } else if (account != null) {
        await notifier.setAccount(account.copyWith(coin: restored));
      }
    }
  }

  Future<void> _pickCount(BuildContext buttonContext) async {
    final button = buttonContext.findRenderObject();
    final overlay = Overlay.of(
      buttonContext,
      rootOverlay: true,
    ).context.findRenderObject();
    if (button is! RenderBox || overlay is! RenderBox || !button.hasSize) {
      return;
    }
    final topLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
    final selected = await showMenu<int>(
      context: buttonContext,
      useRootNavigator: true,
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      constraints: const BoxConstraints(minWidth: 108, maxWidth: 140),
      position: RelativeRect.fromRect(
        Rect.fromLTWH(topLeft.dx, topLeft.dy, button.size.width, 0),
        Offset.zero & overlay.size,
      ),
      items: [
        for (final count in giftCountOptions)
          PopupMenuItem<int>(
            value: count,
            height: 40,
            child: Text(
              '$count个',
              style: const TextStyle(fontSize: 17, color: AppColors.titleText),
            ),
          ),
      ],
    );
    if (selected == null || !mounted || selected == _count) {
      return;
    }
    if (_hits > 0) {
      final pending = _takeCombo();
      if (pending != null) {
        unawaited(_submitCombo(pending));
      }
    }
    setState(() => _count = selected);
  }

  void _storeCoin(int coin) {
    final account = ref.read(accountProvider);
    if (account == null) {
      return;
    }
    ref.read(accountProvider.notifier).setAccount(account.copyWith(coin: coin));
  }

  @override
  Widget build(BuildContext context) {
    final giftModel = _selected;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      bottom: false,
      child: SizedBox(
        height: 460 + bottom,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '送礼物',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            Expanded(child: _buildGrid(context)),
            Container(
              height: 52 + bottom,
              padding: EdgeInsets.only(bottom: bottom),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F3F3),
                border: Border(
                  top: BorderSide(color: Color(0xFFE3E3E3), width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Image.asset(
                    'assets/icons/gift/gift_gold_image.png',
                    width: 26,
                    height: 26,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$_coin',
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  const Spacer(),
                  _GiftCountButton(count: _count, onTap: _pickCount),
                  _GiftSendButton(onTap: giftModel == null ? null : _send),
                  const SizedBox(width: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final scrollController = ModalScrollController.of(context);
    const scrollPhysics = AlwaysScrollableScrollPhysics(
      parent: ClampingScrollPhysics(),
    );
    if (_loading) {
      return ListView(
        controller: scrollController,
        physics: scrollPhysics,
        children: const [
          SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }
    if (_errorText.isNotEmpty) {
      return ListView(
        controller: scrollController,
        physics: scrollPhysics,
        children: [
          SizedBox(
            height: 220,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _errorText,
                    style: const TextStyle(color: Color(0xFF888888)),
                  ),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _load, child: const Text('重试')),
                ],
              ),
            ),
          ),
        ],
      );
    }
    if (_giftModelList.isEmpty) {
      return ListView(
        controller: scrollController,
        physics: scrollPhysics,
        children: const [
          SizedBox(height: 220, child: Center(child: Text('暂无礼物'))),
        ],
      );
    }
    return GridView.builder(
      controller: scrollController,
      physics: scrollPhysics,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.72,
      ),
      itemCount: _giftModelList.length,
      itemBuilder: (context, index) {
        final item = _giftModelList[index];
        final selected = item.giftId == _selectedGiftId;
        return GestureDetector(
          onTap: () {
            if (_hits > 0 && item.giftId != _selectedGiftId) {
              final pending = _takeCombo();
              if (pending != null) {
                unawaited(_submitCombo(pending));
              }
            }
            setState(() => _selectedGiftId = item.giftId);
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFFFF3F5)
                  : const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? const Color(0xFFE85D75) : Colors.transparent,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                children: [
                  Expanded(
                    child: item.pictureUrl.isEmpty
                        ? const Icon(Icons.card_giftcard)
                        : CachedNetworkImage(
                            imageUrl: item.pictureUrl,
                            fit: BoxFit.contain,
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.card_giftcard),
                          ),
                  ),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    '${item.price}金币',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 数量按钮。白底、灰边、左侧圆角，文案如「1个」。
class _GiftCountButton extends StatelessWidget {
  const _GiftCountButton({required this.count, required this.onTap});

  final int count;
  final Future<void> Function(BuildContext context) onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(context),
      child: Container(
        width: 64,
        height: 32,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
          border: Border.fromBorderSide(
            BorderSide(color: Color(0xFFE3E3E3), width: 0.5),
          ),
        ),
        child: Text(
          '$count个',
          style: const TextStyle(fontSize: 15, color: Colors.black),
        ),
      ),
    );
  }
}

/// 发送按钮。蓝色、右侧圆角，和数量按钮拼成一组。
class _GiftSendButton extends StatelessWidget {
  const _GiftSendButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 64,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null
              ? const Color(0xFFB7D7F5)
              : const Color(0xFF3399FF),
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(20),
          ),
        ),
        child: const Text(
          '发送',
          style: TextStyle(fontSize: 15, color: Colors.white),
        ),
      ),
    );
  }
}

class _PendingCombo {
  const _PendingCombo({
    required this.giftModel,
    required this.count,
    required this.spent,
  });

  final GiftModel giftModel;
  final int count;
  final int spent;
}

String _messageOf(Object error) {
  final text = error.toString();
  const prefix = 'Exception: ';
  if (text.startsWith(prefix)) {
    return text.substring(prefix.length);
  }
  return text;
}
