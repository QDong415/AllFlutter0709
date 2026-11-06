import 'package:flutter/material.dart';

/// 连续签到弹窗中的单日奖励格，对齐 `dialog_sign.xml` + [SignDialog.setData]。
class SignDayCellWidget extends StatelessWidget {
  const SignDayCellWidget({
    super.key,
    required this.day,
    required this.rewardText,
    required this.signed,
    required this.isDay7,
  });

  final int day;
  final String rewardText;
  final bool signed;
  final bool isDay7;

  static const _rewardColor = Color(0xFFBD972C);
  static const _dayColor = Color(0xFFFF8000);
  static const _unsignedFill = Color(0xFFFFF7E1);
  static const _unsignedStroke = Color(0xFFFFE59B);
  static const _signedFill = Color(0xFFFEF6E2);
  static const _signedStroke = Color(0xFFFD9E4D);
  static const _signedDayBg = Color(0xFFFFD96C);
  static const _cornerRadius = 4.0;

  String get _coinAsset {
    if (signed) {
      return 'assets/icons/sign/sign_coin_signed.png';
    }
    if (isDay7) {
      return 'assets/icons/sign/sign_much_coin.png';
    }
    return 'assets/icons/sign/sign_coin_unsigned.png';
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = signed ? _signedStroke : _unsignedStroke;
    final fillColor = signed ? _signedFill : _unsignedFill;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(_cornerRadius),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Text(
            rewardText,
            style: const TextStyle(
              fontSize: 14,
              color: _rewardColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Image.asset(_coinAsset, width: 31, height: 31, fit: BoxFit.contain),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            height: 25,
            margin: const EdgeInsets.fromLTRB(2, 0, 2, 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: signed ? _signedDayBg : Colors.transparent,
              borderRadius: signed
                  ? const BorderRadius.vertical(
                      bottom: Radius.circular(_cornerRadius),
                    )
                  : null,
            ),
            child: Text(
              '第$day天',
              style: const TextStyle(fontSize: 13, color: _dayColor),
            ),
          ),
        ],
      ),
    );
  }
}
