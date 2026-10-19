import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/features/auth/presentation/widgets/password_login_view.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 密码登录页。从手机号页 push 进入。
class PasswordLoginPage extends ConsumerStatefulWidget {
  const PasswordLoginPage({super.key, this.initialMobile = ''});

  final String initialMobile;

  @override
  ConsumerState<PasswordLoginPage> createState() => _PasswordLoginPageState();
}

class _PasswordLoginPageState extends ConsumerState<PasswordLoginPage> {
  late final TextEditingController _mobileController;
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _mobileController = TextEditingController(text: widget.initialMobile);
  }

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
    setState(() => _isSubmitting = true);
    try {
      await ref.read(accountProvider.notifier).login(
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
      AppToast.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: PasswordLoginView(
          formKey: _formKey,
          mobileController: _mobileController,
          passwordController: _passwordController,
          isSubmitting: _isSubmitting,
          onBack: () => context.pop(),
          onLogin: _login,
        ),
      ),
    );
  }
}
