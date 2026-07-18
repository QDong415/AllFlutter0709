import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _mobileController = TextEditingController(text: '13800138000');
  final _passwordController = TextEditingController(text: '123456');
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(accountProvider.notifier)
          .login(
            mobile: _mobileController.text.trim(),
            password: _passwordController.text,
          );

      if (mounted) {
        context.go(AppRoutes.topic);
      }
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
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Login',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'iTopic 登录入口',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: '手机号',
                        hintText: '请输入登录手机号',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final mobile = value?.trim() ?? '';
                        if (mobile.isEmpty) {
                          return '请输入手机号';
                        }
                        if (mobile.length < 6) {
                          return '手机号格式不正确';
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
                        if (value == null || value.length < 6) {
                          return '密码至少 6 位';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _login,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('登录'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => context.push(AppRoutes.signup),
                      child: const Text('前往注册'),
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
