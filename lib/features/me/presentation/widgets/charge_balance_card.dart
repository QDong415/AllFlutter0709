import 'package:flutter/material.dart';

/// 充值页金币余额区，对齐 Android `activity_charge` 的 `price_rl` + `lord_ic_money`。
class ChargeBalanceCard extends StatelessWidget {
  const ChargeBalanceCard({
    super.key,
    required this.coinText,
    required this.loading,
  });

  final String coinText;
  final bool loading;

  static const _textBlack = Color(0xFF5B5B5B);

  /// `drawable-xxhdpi/lord_ic_money.png` 为 102px，按 xxhdpi 折算约 34dp。
  static const double _coinIconSize = 34;

  /// 与 `activity_charge.xml` 中 `lord_ic_money` / 白卡片 `layout_marginTop` 一致。
  static const double _iconTop = 23;
  static const double _cardTop = 45;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 40, 14, 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: _cardTop),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 18),
              child: Column(
                children: [
                  Text(
                    loading ? '…' : coinText,
                    style: const TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w700,
                      color: _textBlack,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '金币余额',
                    style: TextStyle(fontSize: 13, color: _textBlack),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: _iconTop,
            left: 0,
            right: 0,
            child: const Center(
              child: Image(
                image: AssetImage('assets/icons/me/lord_ic_money.png'),
                width: _coinIconSize,
                height: _coinIconSize,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
