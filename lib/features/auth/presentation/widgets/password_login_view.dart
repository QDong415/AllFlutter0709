import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 密码登录，对齐 Android `user/login`。
class PasswordLoginView extends StatelessWidget {
  const PasswordLoginView({
    super.key,
    required this.formKey,
    required this.mobileController,
    required this.passwordController,
    required this.isSubmitting,
    required this.onBack,
    required this.onLogin,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController mobileController;
  final TextEditingController passwordController;
  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                children: [
                  Text(
                    '密码登录',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.titleText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '使用已注册的手机号和密码',
                    style: TextStyle(color: Color(0xFF8A8A8A)),
                  ),
                  const SizedBox(height: 32),
                  Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: mobileController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          decoration: const InputDecoration(
                            labelText: '手机号',
                            hintText: '请输入手机号',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if ((value?.trim() ?? '').isEmpty) {
                              return '请输入手机号';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: '密码',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入密码';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: isSubmitting ? null : onLogin,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: const StadiumBorder(),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('登录'),
                          ),
                        ),
                      ],
                    ),
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
