import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/app/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// 删除 AI 对话的确认弹框。
class ConversationAiDeleteDialog extends StatelessWidget {
  const ConversationAiDeleteDialog({super.key});

  /// 返回 `true` 表示用户点了确定。
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierColor: const Color(0x99000000),
      builder: (context) => const ConversationAiDeleteDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = palette.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: palette.card,
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
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        isDark
                            ? const Color(0xFF5C3333)
                            : const Color(0xFFFFE8E8),
                        palette.card,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                    child: Column(
                      children: [
                        const _MemoryIcon(),
                        const SizedBox(height: 16),
                        Text(
                          '删除与 AI 的对话',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                            color: palette.titleText,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'AI 会失去与你的记忆，重新开始。',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: palette.bodyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Divider(height: 1, thickness: 0.6, color: palette.divider),
              SizedBox(
                height: 50,
                child: Row(
                  children: [
                    Expanded(
                      child: _DialogAction(
                        label: '取消',
                        color: palette.bodyText,
                        onTap: () => Navigator.pop(context, false),
                      ),
                    ),
                    SizedBox(
                      width: 0.6,
                      height: 50,
                      child: ColoredBox(color: palette.divider),
                    ),
                    Expanded(
                      child: _DialogAction(
                        label: '确定',
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

/// 顶部记忆图标：品牌色圆底。
class _MemoryIcon extends StatelessWidget {
  const _MemoryIcon();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8A80), AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Icon(
          Icons.psychology_alt_rounded,
          size: 32,
          color: AppColors.white,
        ),
      ),
    );
  }
}

/// 弹框底部均分按钮。
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
