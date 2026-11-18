import 'package:all_flutter0709/app/theme/app_palette.dart';
import 'package:all_flutter0709/features/me/data/wallet_log_model.dart';
import 'package:flutter/material.dart';

/// 金币 / 魅力流水列表的一行。
class WalletLogItem extends StatelessWidget {
  const WalletLogItem({
    super.key,
    required this.walletLogModel,
    required this.unitLabel,
  });

  final WalletLogModel walletLogModel;

  /// 单位文案，如「金币」「魅力」。
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final amount = walletLogModel.amount;
    final isPlus = amount >= 0;
    final amountText = isPlus ? '+$amount' : '$amount';
    final amountColor = isPlus ? const Color(0xFFE85D4C) : palette.bodyText;
    final remark = walletLogModel.remark.trim().isEmpty
        ? '变动'
        : walletLogModel.remark.trim();

    return Container(
      color: palette.card,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  remark,
                  style: TextStyle(
                    fontSize: 15,
                    color: palette.titleText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  walletLogModel.displayTime,
                  style: TextStyle(fontSize: 12, color: palette.secondaryText),
                ),
              ],
            ),
          ),
          Text(
            '$amountText$unitLabel',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
