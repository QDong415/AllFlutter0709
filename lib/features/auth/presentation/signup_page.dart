import 'dart:async';

import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/core/account/account_repository.dart';
import 'package:all_flutter0709/features/auth/presentation/models/signup_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 注册第一步：手机号 + 验证码 + 密码。
class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _mobileController = TextEditingController();
  final _codeController = TextEditingController(text: '0000');
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isRequestingCode = false;
  int _countdownSeconds = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _mobileController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _requestSmsCode() async {
    final mobile = _mobileController.text.trim();
    if (mobile.length != 11) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入 11 位手机号')));
      return;
    }
    if (_countdownSeconds > 0 || _isRequestingCode) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isRequestingCode = true;
    });

    try {
      await ref
          .read(accountRepositoryProvider)
          .requestSmsCode(mobile: mobile);
      if (!mounted) {
        return;
      }
      _startCountdown();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('验证码已发送')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingCode = false;
        });
      }
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _countdownSeconds = 60;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownSeconds <= 1) {
        timer.cancel();
        setState(() {
          _countdownSeconds = 0;
        });
        return;
      }
      setState(() {
        _countdownSeconds -= 1;
      });
    });
  }

  void _goNext() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    context.push(
      AppRoutes.signupProfile,
      extra: SignupArgs(
        mobile: _mobileController.text.trim(),
        code: _codeController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canRequestCode = _countdownSeconds == 0 && !_isRequestingCode;

    return Scaffold(
      appBar: AppBar(title: const Text('注册')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '填写手机号',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '验证码默认 0000，也可点击获取真实验证码',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: '手机号',
                        hintText: '请输入 11 位手机号',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final mobile = value?.trim() ?? '';
                        if (mobile.isEmpty) {
                          return '请输入手机号';
                        }
                        if (mobile.length < 8) {
                          return '请输入正确手机号';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '验证码',
                        border: const OutlineInputBorder(),
                        suffixIcon: TextButton(
                          onPressed: canRequestCode ? _requestSmsCode : null,
                          child: _isRequestingCode
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _countdownSeconds > 0
                                      ? '$_countdownSeconds秒后重获'
                                      : '获取验证码',
                                ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入验证码';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '密码',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入密码';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _goNext,
                      child: const Text('下一步'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text('已有账号，返回登录'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
