import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/features/me/data/wallet_model.dart';
import 'package:all_flutter0709/features/me/data/wallet_repository.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 会员说明。展示价格和特权，购买进入充值说明，不拉起支付。
class VipPage extends StatefulWidget {
  const VipPage({super.key});

  @override
  State<VipPage> createState() => _VipPageState();
}

class _VipPageState extends State<VipPage> {
  final WalletRepository _repository = const WalletRepository();
  VipOfferModel? _offer;
  bool _loading = true;

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

  Future<void> _pickPlan() async {
    final offer = _offer;
    if (offer == null) {
      return;
    }
    final labelList = <String>[
      '${offer.monthPrice}元/月',
      '${offer.seasonPrice}元/季',
      '${offer.yearPrice}元/年',
    ];
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final label in labelList)
                ListTile(
                  title: Text(label, textAlign: TextAlign.center),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push(AppRoutes.meCharge, extra: true);
                  },
                ),
            ],
          ),
        );
      },
    );
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
                  _loading ? '…' : '${offer?.monthPrice ?? 30}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '元/月',
                  style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: 180,
                  child: FilledButton(
                    onPressed: _loading ? null : _pickPlan,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isVip ? '续费' : '充值会员'),
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
