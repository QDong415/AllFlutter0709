import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 对齐 Android `MemoTitleTextStyle` + `LineStyle` 的分段标题。
class CharmWithdrawSectionTitle extends StatelessWidget {
  const CharmWithdrawSectionTitle({
    super.key,
    required this.title,
    this.topGap = false,
  });

  final String title;
  final bool topGap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF3F3F3),
      padding: EdgeInsets.fromLTRB(14, topGap ? 20 : 12, 14, 5),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, color: Color(0xFF919191)),
      ),
    );
  }
}

/// 0.5dp 分割线，对齐 `LineStyle`。
class CharmWithdrawDivider extends StatelessWidget {
  const CharmWithdrawDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 0.5, color: const Color(0xFFE3E3E3));
  }
}

/// 44dp 白底输入行，对齐 Android 提现表单。
class CharmWithdrawInputRow extends StatelessWidget {
  const CharmWithdrawInputRow({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.trailing,
    this.readOnly = false,
    this.backgroundColor = Colors.white,
    this.textColor = const Color(0xFF5B5B5B),
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final Widget? trailing;
  final bool readOnly;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              maxLength: maxLength,
              style: TextStyle(fontSize: 16, color: textColor),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
                border: InputBorder.none,
                counterText: '',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// 「全部提现」小按钮，对齐 `red_round`。
class CharmWithdrawAllButton extends StatelessWidget {
  const CharmWithdrawAllButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFE6766),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            '全部提现',
            style: TextStyle(
              color: onPressed == null ? Colors.white70 : Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

/// 底部「立即提现」，对齐 `red_circle` 大圆角按钮。
class CharmWithdrawSubmitButton extends StatelessWidget {
  const CharmWithdrawSubmitButton({
    super.key,
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 28, 40, 40),
      child: Material(
        color: onPressed == null
            ? const Color(0xFFFE6766).withValues(alpha: 0.5)
            : const Color(0xFFFE6766),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                loading ? '提交中' : '立即提现',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
