import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/features/me/data/wallet_model.dart';
import 'package:all_flutter0709/features/me/data/wallet_repository.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:all_flutter0709/shared/widgets/vip_required_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 会员说明。展示金币月价与特权；续费/充值用金币购买一个月会员。
class VipPage extends ConsumerStatefulWidget {
  const VipPage({super.key});

  @override
  ConsumerState<VipPage> createState() => _VipPageState();
}

class _VipPageState extends ConsumerState<VipPage> {
  final WalletRepository _repository = const WalletRepository();
  VipOfferModel? _offer;
  bool _loading = true;
  bool _buying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final offer = await _repository.fetchVipOffer();
      if (!mounted) {
        return;
      }
      setState(() {
        _offer = offer;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      AppToast.show(context, '$error');
    }
  }

  Future<void> _onBuyTap() async {
    final offer = _offer;
    if (offer == null || _buying) {
      return;
    }
    final cost = offer.monthCoinCost > 0
        ? offer.monthCoinCost
        : VipOfferModel.defaultMonthCoinCost;
    final confirmed = await VipRequiredDialog.show(
      context,
      title: '购买会员',
      message: '是否用 $cost 金币购买一个月会员？',
      confirmText: '确认',
    );
    if (confirmed != true || !mounted) {
      return;
    }
    if (offer.coin < cost) {
      await _showCoinInsufficient();
      return;
    }
    await _buyVipMonth();
  }

  Future<void> _showCoinInsufficient() async {
    final goCharge = await VipRequiredDialog.show(
      context,
      title: '金币不足',
      message: '当前金币不足以购买会员',
      confirmText: '去充值',
      icon: Icons.monetization_on_rounded,
    );
    if (goCharge == true && mounted) {
      context.push(AppRoutes.meCharge);
    }
  }

  Future<void> _buyVipMonth() async {
    setState(() => _buying = true);
    try {
      final result = await _repository.buyVipMonth();
      if (!mounted) {
        return;
      }
      setState(() {
        _offer = VipOfferModel(
          monthCoinCost: result.monthCoinCost > 0
              ? result.monthCoinCost
              : (_offer?.monthCoinCost ?? VipOfferModel.defaultMonthCoinCost),
          coin: result.coin,
          vip: result.vip,
          vipTime: result.vipTime,
        );
      });
      await ref.read(accountProvider.notifier).refreshMyProfile();
      if (!mounted) {
        return;
      }
      AppToast.show(context, '开通成功');
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = '$error';
      if (message.contains('金币不足')) {
        await _showCoinInsufficient();
      } else {
        AppToast.show(context, message);
      }
    } finally {
      if (mounted) {
        setState(() => _buying = false);
      }
    }
  }

  String _expireText(VipOfferModel offer) {
    if (offer.vipTime <= 0) {
      return '您已经是Vip会员';
    }
    final date = DateTime.fromMillisecondsSinceEpoch(offer.vipTime * 1000);
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day 到期';
  }

  @override
  Widget build(BuildContext context) {
    final offer = _offer;
    final isVip = (offer?.vip ?? 0) > 0;
    final cost = offer?.monthCoinCost ?? VipOfferModel.defaultMonthCoinCost;
    return Scaffold(
      backgroundColor: AppColors.bodyBackground,
      appBar: const CommonAppBar(title: '我的Vip'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 20, 14, 24),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  _loading ? '…' : '$cost',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '金币/月',
                  style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: 180,
                  child: FilledButton(
                    onPressed: (_loading || _buying) ? null : _onBuyTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _buying
                          ? '处理中…'
                          : (isVip ? '续费' : '充值会员'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isVip) ...[
            const SizedBox(height: 18),
            const Text(
              '我的Vip',
              style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                offer == null ? '' : _expireText(offer),
                style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
              ),
            ),
          ],
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    '会员特权',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                SizedBox(height: 22),
                Text(
                  '聊天条数不受限制',
                  style: TextStyle(fontSize: 15, color: Color(0xFF333333)),
                ),
                SizedBox(height: 14),
                Text(
                  '聊天可发图片语音视频',
                  style: TextStyle(fontSize: 15, color: Color(0xFF333333)),
                ),
                SizedBox(height: 14),
                Text(
                  '对附近的人优先显示',
                  style: TextStyle(fontSize: 15, color: Color(0xFF333333)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
