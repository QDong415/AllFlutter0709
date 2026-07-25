import 'dart:io';

import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/core/account/account_provider.dart';
import 'package:all_flutter0709/core/qiniu/qiniu_upload_service.dart';
import 'package:all_flutter0709/features/auth/presentation/helpers/signup_avatar_helper.dart';
import 'package:all_flutter0709/features/auth/presentation/models/signup_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 注册第二步：头像（可选）+ 昵称。
class SignupProfilePage extends ConsumerStatefulWidget {
  const SignupProfilePage({super.key, required this.args});

  final SignupArgs args;

  @override
  ConsumerState<SignupProfilePage> createState() => _SignupProfilePageState();
}

class _SignupProfilePageState extends ConsumerState<SignupProfilePage> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  SignupAvatarHelper? _avatarHelper;
  File? _localAvatarFile;
  String? _uploadedAvatarKey;
  bool _isUploadingAvatar = false;
  bool _isSubmitting = false;

  SignupAvatarHelper get _helper {
    return _avatarHelper ??= SignupAvatarHelper(
      qiniuUploadService: ref.read(qiniuUploadServiceProvider),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    if (_isUploadingAvatar || _isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();
    final cropped = await _helper.pickAndCropAvatar();
    if (cropped == null || !mounted) {
      return;
    }

    setState(() {
      _localAvatarFile = cropped;
      _uploadedAvatarKey = null;
      _isUploadingAvatar = true;
    });

    try {
      final key = await _helper.uploadAvatar(cropped);
      if (!mounted) {
        return;
      }
      setState(() {
        _uploadedAvatarKey = key;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _localAvatarFile = null;
        _uploadedAvatarKey = null;
      });
      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('头像上传失败：$message')));
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_isUploadingAvatar) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('头像上传中，请稍候')));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(accountProvider.notifier)
          .register(
            mobile: widget.args.mobile,
            code: widget.args.code,
            name: _nameController.text.trim(),
            password: widget.args.password,
            avatar: _uploadedAvatarKey ?? '',
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
    final busy = _isSubmitting || _isUploadingAvatar;

    return Scaffold(
      appBar: AppBar(title: const Text('完善资料')),
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
                    Center(
                      child: GestureDetector(
                        onTap: busy ? null : _pickAvatar,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              backgroundImage: _localAvatarFile == null
                                  ? null
                                  : FileImage(_localAvatarFile!),
                              child: _localAvatarFile == null
                                  ? Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 28,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    )
                                  : null,
                            ),
                            if (_isUploadingAvatar)
                              const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '点击上传头像（可选）',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: '昵称',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入昵称';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: busy ? null : _register,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('完成注册'),
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
