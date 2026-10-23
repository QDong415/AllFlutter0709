import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// 设置或清除给某个用户的备注。返回 null 表示取消，空字符串表示清除。
Future<String?> showUserRemarkDialog(
  BuildContext context, {
  required String nickname,
  required String initialRemark,
  int maxLength = 16,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _UserRemarkDialog(
      nickname: nickname,
      initialRemark: initialRemark,
      maxLength: maxLength,
    ),
  );
}

/// 备注输入弹框：白底圆角，底部「取消 / 保存」。
class _UserRemarkDialog extends StatefulWidget {
  const _UserRemarkDialog({
    required this.nickname,
    required this.initialRemark,
    required this.maxLength,
  });

  final String nickname;
  final String initialRemark;
  final int maxLength;

  @override
  State<_UserRemarkDialog> createState() => _UserRemarkDialogState();
}

class _UserRemarkDialogState extends State<_UserRemarkDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialRemark,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final nickname = widget.nickname.trim();
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
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
                child: Column(
                  children: [
                    const Text(
                      '设置备注',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.titleText,
                      ),
                    ),
                    if (nickname.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        nickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      maxLength: widget.maxLength,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _save(),
                      decoration: const InputDecoration(
                        hintText: '备注名，仅自己可见',
                        isDense: true,
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 0.6, color: AppColors.divider),
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    Expanded(
                      child: _DialogAction(
                        label: '取消',
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
                        label: '保存',
                        color: AppColors.link,
                        fontWeight: FontWeight.w600,
                        onTap: _save,
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
