import 'package:all_flutter0709/features/user/data/user_repository.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 修改密码，对齐 Android `MineSystemPasswordActivity`。
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final UserRepository _userRepository = const UserRepository();
  final TextEditingController _oldController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final oldPassword = _oldController.text.trim();
    final password = _newController.text.trim();
    final confirm = _confirmController.text.trim();
    if (oldPassword.isEmpty || password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('密码不能为空')));
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('两次密码不一致')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await _userRepository.changePassword(
        oldPassword: oldPassword,
        password: password,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('修改成功')));
      context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '修改密码'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _oldController,
            obscureText: true,
            decoration: const InputDecoration(labelText: '原密码'),
          ),
          TextField(
            controller: _newController,
            obscureText: true,
            decoration: const InputDecoration(labelText: '新密码'),
          ),
          TextField(
            controller: _confirmController,
            obscureText: true,
            decoration: const InputDecoration(labelText: '确认新密码'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: const Text('确认修改'),
          ),
        ],
      ),
    );
  }
}
