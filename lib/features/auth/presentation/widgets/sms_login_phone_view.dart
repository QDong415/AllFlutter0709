import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/network/app_env.dart';
import 'package:all_flutter0709/features/auth/presentation/agreement_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 短信登录第一步：输入手机号并获取验证码。
class SmsLoginPhoneView extends StatefulWidget {
  const SmsLoginPhoneView({
    super.key,
    required this.mobileController,
    required this.agreed,
    required this.countdownSeconds,
    required this.isRequestingCode,
    required this.onAgreedChanged,
    required this.onRequestCode,
    required this.onPasswordLogin,
  });

  final TextEditingController mobileController;
  final bool agreed;
  final int countdownSeconds;
  final bool isRequestingCode;
  final ValueChanged<bool> onAgreedChanged;
  final VoidCallback onRequestCode;
  final VoidCallback onPasswordLogin;

  @override
  State<SmsLoginPhoneView> createState() => _SmsLoginPhoneViewState();
}

class _SmsLoginPhoneViewState extends State<SmsLoginPhoneView> {
  late final TapGestureRecognizer _userAgreementRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _userAgreementRecognizer = TapGestureRecognizer()
      ..onTap = () => AgreementPage.open(
        context,
        title: '用户协议',
        url: '${AppEnv.apiBaseUrl}/home/article/agreement?agreementid=1',
      );
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => AgreementPage.open(
        context,
        title: '隐私政策',
        url: '${AppEnv.apiBaseUrl}/home/article/agreement?agreementid=2',
      );
  }

  @override
  void dispose() {
    _userAgreementRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canRequest =
        widget.countdownSeconds == 0 && !widget.isRequestingCode;
    final buttonText = widget.countdownSeconds > 0
        ? '${widget.countdownSeconds}秒后重获'
        : '获取验证码';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 48, 28, 24),
          children: [
            const SizedBox(height: 24),
            const _BrandMark(),
            const SizedBox(height: 36),
            TextField(
              controller: widget.mobileController,
              keyboardType: TextInputType.phone,
              autofocus: false,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              decoration: InputDecoration(
                hintText: '请输入手机号',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 14, right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('+86', style: TextStyle(color: AppColors.titleText)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, color: AppColors.titleText),
                      SizedBox(
                        width: 1,
                        height: 18,
                        child: ColoredBox(color: AppColors.divider),
                      ),
                    ],
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: canRequest ? widget.onRequestCode : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withValues(
                    alpha: 0.45,
                  ),
                  shape: const StadiumBorder(),
                ),
                child: widget.isRequestingCode
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(buttonText),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: widget.agreed,
                  activeColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (value) => widget.onAgreedChanged(value ?? false),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8A8A8A),
                      ),
                      children: [
                        const TextSpan(text: '登录即同意'),
                        TextSpan(
                          text: '《用户协议》',
                          style: const TextStyle(color: AppColors.link),
                          recognizer: _userAgreementRecognizer,
                        ),
                        const TextSpan(text: '和'),
                        TextSpan(
                          text: '《隐私政策》',
                          style: const TextStyle(color: AppColors.link),
                          recognizer: _privacyRecognizer,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: widget.onPasswordLogin,
              child: const Text(
                '使用密码登录',
                style: TextStyle(color: AppColors.titleText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 登录页品牌标记。
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/icons/app_logo.png',
          width: 88,
          height: 72,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 16),
        Text(
          '爱说说',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.titleText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
