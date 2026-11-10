import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// 魅力提现申请成功弹窗，对齐 Buddy `ApplySuccessDialog` + `dialog_apply_success.xml`。
class CharmWithdrawApplySuccessDialog extends StatelessWidget {
  const CharmWithdrawApplySuccessDialog({
    super.key,
    required this.onConfirm,
  });

  final VoidCallback onConfirm;

  /// 展示弹窗；点「确 定」后先关弹窗再执行 [onConfirm]（通常关闭提现页）。
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return CharmWithdrawApplySuccessDialog(
          onConfirm: () {
            Navigator.of(dialogContext).pop();
            onConfirm();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 280),
        child: Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/me/apply_success.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 20),
                    const Text(
                      '提交成功',
                      style: TextStyle(
                        color: AppColors.link,
                        fontSize: 17,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: AppColors.link,
                child: InkWell(
                  onTap: onConfirm,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Text(
                        '确 定',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
