import 'package:all_flutter0709/app/app_flags.dart';
import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 短信登录第二步：输入 4 位验证码。
class SmsLoginCodeView extends StatefulWidget {
  const SmsLoginCodeView({
    super.key,
    required this.mobile,
    required this.codeController,
    required this.countdownSeconds,
    required this.isRequestingCode,
    required this.isSubmitting,
    required this.onBack,
    required this.onResend,
    required this.onCompleted,
  });

  final String mobile;
  final TextEditingController codeController;
  final int countdownSeconds;
  final bool isRequestingCode;
  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onResend;
  final ValueChanged<String> onCompleted;

  @override
  State<SmsLoginCodeView> createState() => _SmsLoginCodeViewState();
}

class _SmsLoginCodeViewState extends State<SmsLoginCodeView> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(SmsLoginCodeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSubmitting && !widget.isSubmitting) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.codeController.text;
    final canResend = widget.countdownSeconds == 0 && !widget.isRequestingCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                children: [
                  Text(
                    '输入验证码',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.titleText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '验证码已发送至 +86 ${_maskMobile(widget.mobile)}',
                    style: const TextStyle(color: Color(0xFF8A8A8A)),
                  ),
                  const SizedBox(height: 36),
                  _CodeBoxes(
                    code: code,
                    focusNode: _focusNode,
                    controller: widget.codeController,
                    enabled: !widget.isSubmitting,
                    onChanged: (_) => setState(() {}),
                    onCompleted: widget.onCompleted,
                  ),
                  const SizedBox(height: 20),
                  if (AppFlags.testLogin) ...[
                    const Text(
                      '测试可输入 0000，无需短信验证码',
                      style: TextStyle(color: Color(0xFF8A8A8A)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (widget.isSubmitting)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (widget.countdownSeconds > 0)
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(color: Color(0xFF8A8A8A)),
                        children: [
                          TextSpan(
                            text: '${widget.countdownSeconds}',
                            style: const TextStyle(color: AppColors.primary),
                          ),
                          const TextSpan(text: ' 秒后可重新获取'),
                        ],
                      ),
                    )
                  else
                    TextButton(
                      onPressed: canResend ? widget.onResend : null,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppColors.primary,
                      ),
                      child: Text(widget.isRequestingCode ? '发送中…' : '重新发送'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 四位验证码格子，点击后拉起数字键盘。
class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({
    required this.code,
    required this.focusNode,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.onCompleted,
  });

  final String code;
  final FocusNode focusNode;
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              keyboardType: TextInputType.number,
              showCursor: false,
              enableSuggestions: false,
              autocorrect: false,
              style: const TextStyle(color: Colors.transparent, fontSize: 1),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              onChanged: (value) {
                onChanged(value);
                if (value.length == 4) {
                  onCompleted(value);
                }
              },
            ),
          ),
          IgnorePointer(
            child: Row(
              children: [
                for (var index = 0; index < 4; index++) ...[
                  if (index > 0) const SizedBox(width: 12),
                  Expanded(
                    child: _CodeBox(
                      digit: _digitAt(index),
                      focused: _isFocused(index),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _digitAt(int index) {
    if (index < 0 || index >= code.length) {
      return '';
    }
    return code[index];
  }

  bool _isFocused(int index) => code.length == index;
}

/// 单个验证码格子。
class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.digit, required this.focused});

  final String digit;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focused ? AppColors.primary : AppColors.divider,
          width: focused ? 1.5 : 1,
        ),
      ),
      child: Center(
        child: digit.isEmpty
            ? (focused
                  ? Container(width: 2, height: 22, color: AppColors.primary)
                  : const SizedBox.shrink())
            : Text(
                digit,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.titleText,
                ),
              ),
      ),
    );
  }
}

String _maskMobile(String mobile) {
  if (mobile.length < 7) {
    return mobile;
  }
  return '${mobile.substring(0, 3)}****${mobile.substring(mobile.length - 4)}';
}
