import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/features/me/data/wallet_model.dart';
import 'package:all_flutter0709/features/me/data/wallet_repository.dart';
import 'package:all_flutter0709/features/me/presentation/widgets/charm_withdraw_balance_card.dart';
import 'package:all_flutter0709/features/me/presentation/widgets/charm_withdraw_form_rows.dart';
import 'package:all_flutter0709/features/me/presentation/widgets/charm_withdraw_success_dialog.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 魅力提现申请。布局对齐 Android `MineTakeMoneyActivity`。
class CharmWithdrawPage extends ConsumerStatefulWidget {
  const CharmWithdrawPage({super.key});

  @override
  ConsumerState<CharmWithdrawPage> createState() => _CharmWithdrawPageState();
}

class _CharmWithdrawPageState extends ConsumerState<CharmWithdrawPage> {
  final WalletRepository _repository = const WalletRepository();
  final TextEditingController _charmController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  CharmCashModel? _cash;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _charmController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _charmController.dispose();
    _accountController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final cash = await _repository.fetchCharmCash();
      if (!mounted) {
        return;
      }
      final account = ref.read(accountProvider);
      if (account != null) {
        await ref
            .read(accountProvider.notifier)
            .setAccount(account.copyWith(charm: cash.charm));
      }
      _charmController.text = '${cash.charm}';
      _accountController.text = cash.account;
      _nameController.text = cash.realName;
      setState(() {
        _cash = cash;
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

  String _inputYuanLabel(int scale) {
    final text = _charmController.text.trim();
    if (text.isEmpty) {
      return '0元';
    }
    final charm = int.tryParse(text) ?? 0;
    return formatCharmToYuanLabel(charm, scale);
  }

  Future<void> _submit() async {
    final cash = _cash;
    if (cash == null || _submitting) {
      return;
    }
    final charm = int.tryParse(_charmController.text.trim()) ?? 0;
    final account = _accountController.text.trim();
    final realName = _nameController.text.trim();
    if (charm <= 0) {
      AppToast.show(context, '输入要提现的魅力');
      return;
    }
    if (charm > cash.charm) {
      AppToast.show(context, '金额不能大于可结余额');
      return;
    }
    if (charm < 1000) {
      AppToast.show(context, '达到1000魅力才能提现');
      return;
    }
    if (account.isEmpty) {
      AppToast.show(context, '请填写支付宝账号');
      return;
    }
    if (realName.isEmpty) {
      AppToast.show(context, '请填写真实姓名');
      return;
    }
    setState(() => _submitting = true);
    try {
      await _repository.applyCharmWithdraw(
        charm: charm,
        cashScale: cash.cashScale,
        account: account,
        realName: realName,
      );
      final loggedIn = ref.read(accountProvider);
      if (loggedIn != null) {
        await ref.read(accountProvider.notifier).setAccount(
              loggedIn.copyWith(charm: cash.charm - charm),
            );
      }
      if (!mounted) {
        return;
      }
      await CharmWithdrawApplySuccessDialog.show(
        context,
        onConfirm: () {
          if (context.mounted) {
            context.pop();
          }
        },
      );
    } catch (error) {
      if (mounted) {
        AppToast.show(context, '$error');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cash = _cash;
    final scale = cash?.cashScale ?? 20;
    final charm = cash?.charm ?? 0;
    final avatar = ref.watch(accountProvider)?.avatar;
    final canSubmit = !_loading && !_submitting && cash != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: const CommonAppBar(title: '申请提现'),
      body: ListView(
        children: [
          CharmWithdrawBalanceCard(
            loading: _loading,
            yuanLabel: formatCharmToYuanLabel(charm, scale),
            scaleHint: '$scale魅力=1元，当前我的魅力值：$charm',
            avatarUrl: charmWithdrawAvatarUrl(avatar),
          ),
          const CharmWithdrawSectionTitle(title: '想提现多少魅力值'),
          const CharmWithdrawDivider(),
          CharmWithdrawInputRow(
            controller: _charmController,
            hintText: '要提现的魅力值',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            trailing: CharmWithdrawAllButton(
              onPressed: cash == null
                  ? null
                  : () => _charmController.text = '${cash.charm}',
            ),
          ),
          const CharmWithdrawDivider(),
          const CharmWithdrawSectionTitle(title: '可转为现金：'),
          const CharmWithdrawDivider(),
          Container(
            height: 44,
            width: double.infinity,
            color: const Color(0xFFEEEEEE),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              _inputYuanLabel(scale),
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
          const CharmWithdrawDivider(),
          const CharmWithdrawSectionTitle(title: '支付宝账号', topGap: true),
          const CharmWithdrawDivider(),
          CharmWithdrawInputRow(
            controller: _accountController,
            hintText: '提现到支付宝账号',
            maxLength: 30,
          ),
          const CharmWithdrawDivider(),
          const CharmWithdrawSectionTitle(title: '真实姓名'),
          const CharmWithdrawDivider(),
          CharmWithdrawInputRow(
            controller: _nameController,
            hintText: '支付宝账号对应的真实姓名',
            maxLength: 15,
          ),
          const CharmWithdrawDivider(),
          CharmWithdrawSubmitButton(
            loading: _submitting,
            onPressed: canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }
}
