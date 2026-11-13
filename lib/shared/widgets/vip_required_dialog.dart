import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// VIP / 会员相关确认弹框：白底、顶栏粉渐变与主色行动按钮。
class VipRequiredDialog extends StatelessWidget {
  const VipRequiredDialog({
    super.key,
    required this.title,
    required this.message,
    this.cancelText = '取消',
    this.confirmText = '现在开通',
    this.icon = Icons.workspace_premium_rounded,
  });

  final String title;
  final String message;
  final String cancelText;
  final String confirmText;
  final IconData icon;

  /// 返回 `true` 表示用户点了确认侧按钮。
  static Future<bool?> show(
    BuildContext context, {
    String title = '开通 VIP 会员',
    String message = '开通 Vip 会员后才可享受此功能，确定要开通吗？',
    String cancelText = '取消',
    String confirmText = '现在开通',
    IconData icon = Icons.workspace_premium_rounded,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: const Color(0x99000000),
      builder: (context) => VipRequiredDialog(
        title: title,
        message: message,
        cancelText: cancelText,
        confirmText: confirmText,
        icon: icon,
      ),
    );
  }

  static const _headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFEFEF),
      Color(0xFFFFFFFF),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shadowColor: const Color(0x40000000),
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 强制顶栏拉满宽度，避免 DecoratedBox 只包内容导致左右留白
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: const BoxDecoration(gradient: _headerGradient),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                    child: Column(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFF8A80),
                                AppColors.primary,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Icon(
                              icon,
                              size: 32,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                            color: AppColors.titleText,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 0.6, color: AppColors.divider),
              SizedBox(
                height: 50,
                child: Row(
                  children: [
                    Expanded(
                      child: _VipDialogAction(
                        label: cancelText,
                        color: const Color(0xFF5B5B5B),
                        onTap: () => Navigator.pop(context, false),
                      ),
                    ),
                    const SizedBox(
                      width: 0.6,
                      height: 50,
                      child: ColoredBox(color: AppColors.divider),
                    ),
                    Expanded(
                      child: _VipDialogAction(
                        label: confirmText,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        onTap: () => Navigator.pop(context, true),
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

class _VipDialogAction extends StatelessWidget {
  const _VipDialogAction({
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 17,
              color: color,
              fontWeight: fontWeight,
            ),
          ),
        ),
      ),
    );
  }
}
