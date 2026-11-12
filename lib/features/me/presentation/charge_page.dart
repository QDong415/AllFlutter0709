import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/core/config/app_config.dart';
import 'package:all_flutter0709/features/conversation/presentation/helpers/conversation_chat_args.dart';
import 'package:all_flutter0709/features/me/data/wallet_model.dart';
import 'package:all_flutter0709/features/me/data/wallet_repository.dart';
import 'package:all_flutter0709/features/me/presentation/widgets/charge_balance_card.dart';
import 'package:all_flutter0709/features/me/presentation/widgets/charge_methods_card.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 充值说明。布局对齐 Android `ChargeActivity` / `activity_charge.xml`。
class ChargePage extends ConsumerStatefulWidget {
  const ChargePage({super.key, this.forVip = false});

  /// 从会员页进来时标题是「充值会员」，不展示金币余额（`activity_chargevip`）。
  final bool forVip;

  @override
  ConsumerState<ChargePage> createState() => _ChargePageState();
}

class _ChargePageState extends ConsumerState<ChargePage> {
  final WalletRepository _repository = const WalletRepository();
  final TextEditingController _promoCodeController = TextEditingController();
  ChargeGuideModel? _guide;
  bool _loading = true;
  bool _redeeming = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _promoCodeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final guide = await _repository.fetchChargeGuide();
      if (!mounted) {
        return;
      }
      await _syncCoin(guide.coin);
      setState(() {
        _guide = guide;
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

  Future<void> _syncCoin(int coin) async {
    final account = ref.read(accountProvider);
    if (account == null) {
      return;
    }
    await ref
        .read(accountProvider.notifier)
        .setAccount(account.copyWith(coin: coin));
  }

  void _openSecretary() {
    final guide = _guide;
    final userId = guide?.secretaryUserId.trim() ?? '';
    if (userId.isEmpty) {
      AppToast.show(context, '客服账号还没准备好');
      return;
    }
    context.push(
      '${AppRoutes.conversation}/chat/$userId',
      extra: ConversationChatArgs(
        peerName: guide?.secretaryName,
        peerAvatar: guide?.secretaryAvatar,
      ),
    );
  }

  Future<void> _redeemPromoCode() async {
    final code = _promoCodeController.text.trim();
    if (code.isEmpty) {
      AppToast.show(context, '请输入兑换码');
      return;
    }
    if (_redeeming) {
      return;
    }
    setState(() => _redeeming = true);
    try {
      final result = await _repository.redeemPromoCode(code);
      if (!mounted) {
        return;
      }
      await _syncCoin(result.coin);
      final guide = _guide;
      setState(() {
        _redeeming = false;
        if (guide != null) {
          _guide = ChargeGuideModel(
            coin: result.coin,
            secretaryUserId: guide.secretaryUserId,
            secretaryName: guide.secretaryName,
            secretaryAvatar: guide.secretaryAvatar,
          );
        }
      });
      _promoCodeController.clear();
      AppToast.show(context, result.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _redeeming = false);
      AppToast.show(context, '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final guide = _guide;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: CommonAppBar(title: widget.forVip ? '充值会员' : '充值金币'),
      body: ListView(
        children: [
          if (!widget.forVip)
            ChargeBalanceCard(
              loading: _loading,
              coinText: '${guide?.coin ?? 0}',
            ),
          ChargeMethodsCard(
            secretaryName: guide?.secretaryName ?? '',
            secretaryAvatar: guide?.secretaryAvatar ?? '',
            way2Text: AppConfig.instance.payWay2,
            promoCodeController: _promoCodeController,
            loading: _loading,
            redeeming: _redeeming,
            onContactTap: _openSecretary,
            onRedeemTap: _redeemPromoCode,
          ),
        ],
      ),
    );
  }
}
