import 'package:flutter/material.dart';

/// 签到成功弹窗，对齐 Buddy `SignSuccessDialog` + `dialog_sign_success.xml`。
class SignSuccessDialog extends StatelessWidget {
  const SignSuccessDialog({
    super.key,
    required this.awardCoin,
    required this.streakDays,
    required this.onConfirm,
  });

  final int awardCoin;
  final int streakDays;
  final VoidCallback onConfirm;

  static const _confirmTextColor = Color(0xFFF0514A);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final panelHeight = width * 0.99;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: width,
        height: panelHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/icons/sign/sign_success_bg.png',
              fit: BoxFit.fill,
            ),
            Column(
              children: [
                const Expanded(child: SizedBox.shrink()),
                Text(
                  '+ $awardCoin 金币',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '已经连续签到 $streakDays 天',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: onConfirm,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/icons/sign/sign_success_button.png',
                        height: 36,
                        fit: BoxFit.fitHeight,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          '确定',
                          style: TextStyle(
                            fontSize: 17,
                            color: _confirmTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 17),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
