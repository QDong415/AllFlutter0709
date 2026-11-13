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
    final amount = walletLogModel.amount;
    final isPlus = amount >= 0;
    final amountText = isPlus ? '+$amount' : '$amount';
    final amountColor = isPlus
        ? const Color(0xFFE85D4C)
        : const Color(0xFF5B5B5B);
    final remark = walletLogModel.remark.trim().isEmpty
        ? '变动'
        : walletLogModel.remark.trim();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  remark,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  walletLogModel.displayTime,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF919191),
                  ),
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
