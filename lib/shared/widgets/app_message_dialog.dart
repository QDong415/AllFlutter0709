import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// 居中说明弹框：白底圆角，底部「取消 / 确认」均分。
class AppMessageDialog extends StatelessWidget {
  const AppMessageDialog({
    super.key,
    required this.message,
    this.cancelText = '取消',
    this.confirmText = '知道了',
  });

  final String message;
  final String cancelText;
  final String confirmText;

  /// 弹出说明弹框。两个按钮都只关闭弹框。
  static Future<void> show(
    BuildContext context, {
    required String message,
    String cancelText = '取消',
    String confirmText = '知道了',
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AppMessageDialog(
        message: message,
        cancelText: cancelText,
        confirmText: confirmText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: const Color(0x33000000),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: AppColors.titleText,
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 0.6, color: AppColors.divider),
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    Expanded(
                      child: _DialogAction(
                        label: cancelText,
                        color: const Color(0xFF5B5B5B),
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(
                      width: 0.6,
                      height: 48,
                      child: ColoredBox(color: AppColors.divider),
                    ),
                    Expanded(
                      child: _DialogAction(
                        label: confirmText,
                        color: AppColors.link,
                        fontWeight: FontWeight.w600,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 弹框底部的均分文字按钮。
class _DialogAction extends StatelessWidget {
  const _DialogAction({
    required this.label,
    required this.color,
    required this.onTap,
    this.fontWeight = FontWeight.w500,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Center(
        child: Text(
          label,
          style: TextStyle(fontSize: 17, color: color, fontWeight: fontWeight),
        ),
      ),
    );
  }
}
