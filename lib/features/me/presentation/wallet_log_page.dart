import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/features/me/data/wallet_log_model.dart';
import 'package:all_flutter0709/features/me/data/wallet_repository.dart';
import 'package:all_flutter0709/features/me/presentation/widgets/wallet_log_item.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:all_flutter0709/shared/widgets/page_state_view.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';

/// 钱包流水类型：金币或魅力。
enum WalletLogKind {
  coin,
  charm,
}

/// 金币 / 魅力变动记录列表。
class WalletLogPage extends StatefulWidget {
  const WalletLogPage({
    super.key,
    required this.kind,
  });

  final WalletLogKind kind;

  @override
  State<WalletLogPage> createState() => _WalletLogPageState();
}

class _WalletLogPageState extends State<WalletLogPage> {
  final WalletRepository _walletRepository = const WalletRepository();
  final List<WalletLogModel> _walletLogModelList = <WalletLogModel>[];
  int _nextPage = 1;
  bool _hasMore = true;
  PageState _pageState = PageState.loading;

  bool get _isCoin => widget.kind == WalletLogKind.coin;

  String get _title => _isCoin ? '金币变动记录' : '魅力值变动记录';

  String get _unitLabel => _isCoin ? '金币' : '魅力';

  String get _emptyText => _isCoin ? '暂无金币变动' : '暂无魅力值变动';

  @override
  void initState() {
    super.initState();
    _request(isRefresh: true);
  }

  Future<void> _request({required bool isRefresh}) async {
    final page = isRefresh ? 1 : _nextPage;
    try {
      final result = _isCoin
          ? await _walletRepository.fetchMoneyLogList(page: page)
          : await _walletRepository.fetchCharmLogList(page: page);
      if (!mounted) {
        return;
      }
      setState(() {
        if (isRefresh) {
          _walletLogModelList
            ..clear()
            ..addAll(result.items);
          _nextPage = 2;
        } else {
          _walletLogModelList.addAll(result.items);
          _nextPage++;
        }
        _hasMore = result.hasMore;
        _pageState = _walletLogModelList.isEmpty
            ? PageState.empty
            : PageState.success;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      if (_walletLogModelList.isEmpty) {
        setState(() => _pageState = PageState.error);
      }
      AppToast.show(context, '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bodyBackground,
      appBar: CommonAppBar(title: _title),
      body: EasyRefresh(
        onRefresh: () => _request(isRefresh: true),
        onLoad: _hasMore ? () => _request(isRefresh: false) : null,
        child: PageStateView(
          state: _pageState,
          emptyText: _emptyText,
          onRefresh: () => _request(isRefresh: true),
          successWidget: ListView.separated(
            itemCount: _walletLogModelList.length,
            separatorBuilder: (_, _) => const Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: AppColors.divider,
            ),
            itemBuilder: (context, index) {
              return WalletLogItem(
                walletLogModel: _walletLogModelList[index],
                unitLabel: _unitLabel,
              );
            },
          ),
        ),
      ),
    );
  }
}
