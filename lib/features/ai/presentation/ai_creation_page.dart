import 'dart:async';

import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/features/ai/data/ai_creation_repository.dart';
import 'package:all_flutter0709/features/ai/data/models/ai_creation_model.dart';
import 'package:all_flutter0709/features/ai/presentation/widgets/ai_creation_form.dart';
import 'package:all_flutter0709/features/ai/presentation/widgets/ai_generation_animation.dart';
import 'package:all_flutter0709/shared/widgets/app_message_dialog.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 用户自定义 AI：设定、同步生图、预览和确认发布。
class AiCreationPage extends StatefulWidget {
  const AiCreationPage({super.key});

  @override
  State<AiCreationPage> createState() => _AiCreationPageState();
}

class _AiCreationPageState extends State<AiCreationPage> {
  final AiCreationRepository _repository = const AiCreationRepository();

  _CreationPhase _phase = _CreationPhase.form;
  AiCreationFormValue? _formValue;
  AiCreationModel? _creationModel;
  String _errorMessage = '';

  bool get _isBusy =>
      _phase == _CreationPhase.creating ||
      _phase == _CreationPhase.generatingAvatar ||
      _phase == _CreationPhase.generatingFullBody ||
      _phase == _CreationPhase.confirming;

  Future<void> _start(AiCreationFormValue formValue) async {
    _formValue = formValue;
    _creationModel = null;
    setState(() {
      _phase = _CreationPhase.creating;
      _errorMessage = '';
    });
    try {
      _creationModel = await _repository.create(
        name: formValue.name,
        gender: formValue.gender,
        personality: formValue.personality,
        outfit: formValue.outfit,
        career: formValue.career,
        personaInput: formValue.personaInput,
      );
      if (!mounted) return;
      if (formValue.personaInput.isNotEmpty &&
          _creationModel?.moderationStatus == 'fallback') {
        AppToast.show(context, '补充人设暂未应用，已使用默认性格模板');
      }
      await _generateAvatar();
    } catch (error) {
      if (!mounted) return;
      setState(() => _phase = _CreationPhase.form);
      await _showErrorDialog(_errorText(error));
    }
  }

  Future<void> _generateAvatar() async {
    final creationModel = _creationModel;
    if (creationModel == null) return;
    setState(() {
      _phase = _CreationPhase.generatingAvatar;
      _errorMessage = '';
    });
    try {
      _creationModel = await _repository.generateAvatar(
        creationModel.creationId,
      );
      if (!mounted) return;
      await _generateFullBody();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _generateFullBody() async {
    final creationModel = _creationModel;
    if (creationModel == null) return;
    setState(() {
      _phase = _CreationPhase.generatingFullBody;
      _errorMessage = '';
    });
    try {
      _creationModel = await _repository.generateFullBody(
        creationModel.creationId,
      );
      if (!mounted) return;
      setState(() => _phase = _CreationPhase.preview);
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    final message = _errorText(error);
    setState(() {
      _phase = _CreationPhase.error;
      _errorMessage = message;
    });
    unawaited(_showErrorDialog(message));
  }

  String _errorText(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  Future<void> _showErrorDialog(String message) {
    return AppMessageDialog.show(
      context,
      message: message,
      cancelText: '关闭',
      confirmText: '知道了',
    );
  }

  Future<void> _retry() async {
    final creationModel = _creationModel;
    if (creationModel == null) {
      final formValue = _formValue;
      if (formValue != null) {
        await _start(formValue);
      }
      return;
    }
    if (creationModel.avatarImage.isEmpty) {
      await _generateAvatar();
    } else {
      await _generateFullBody();
    }
  }

  Future<void> _confirm() async {
    final creationModel = _creationModel;
    if (creationModel == null) return;
    setState(() => _phase = _CreationPhase.confirming);
    try {
      final publishedModel = await _repository.confirm(
        creationModel.creationId,
      );
      if (!mounted) return;
      AppToast.show(context, '${publishedModel.name} 已创建');
      context.pop(true);
    } catch (error) {
      _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isBusy,
      child: Scaffold(
        backgroundColor: AppColors.bodyBackground,
        appBar: AppBar(
          title: const Text('创建 AI 伙伴'),
          backgroundColor: AppColors.toolbar,
          surfaceTintColor: Colors.transparent,
        ),
        body: switch (_phase) {
          _CreationPhase.form => AiCreationForm(
            initialValue: _formValue,
            onSubmit: _start,
          ),
          _CreationPhase.creating => const AiGenerationAnimation(
            title: '正在构思角色',
            detail: '正在整理性格、职业与穿搭设定…',
          ),
          _CreationPhase.generatingAvatar => const AiGenerationAnimation(
            title: '正在生成头像',
            detail: 'AI 正在勾勒五官和发型，这通常需要几十秒。',
          ),
          _CreationPhase.generatingFullBody => const AiGenerationAnimation(
            title: '正在绘制全身形象',
            detail: '我们会锁定头像中的角色，继续完成服装和全身构图。',
          ),
          _CreationPhase.preview => _buildPreview(),
          _CreationPhase.confirming => const AiGenerationAnimation(
            title: '正在创建伙伴',
            detail: '图片已经确认，正在完成最后的角色资料。',
          ),
          _CreationPhase.error => _buildError(),
        },
      ),
    );
  }

  Widget _buildPreview() {
    final creationModel = _creationModel!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 36),
      children: [
        Text(
          '${creationModel.name} 已经准备好了',
          style: const TextStyle(
            color: AppColors.titleText,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          '确认后角色会正式发布，并出现在 AI 伙伴列表中。',
          style: TextStyle(color: Color(0xFF777777), fontSize: 14),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _PreviewImage(
                title: '头像',
                imageUrl: creationModel.avatarUrl!,
                aspectRatio: 1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PreviewImage(
                title: '全身形象',
                imageUrl: creationModel.fullBodyImageUrl!,
                aspectRatio: 3 / 4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _confirm,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('确认创建'),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_outlined,
              size: 58,
              color: AppColors.primary,
            ),
            const SizedBox(height: 18),
            const Text(
              '这次生成没有完成',
              style: TextStyle(
                color: AppColors.titleText,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF777777),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重试当前步骤'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({
    required this.title,
    required this.imageUrl,
    required this.aspectRatio,
  });

  final String title;
  final String imageUrl;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.titleText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, _) => const ColoredBox(
                color: Color(0xFFE7E7E7),
                child: Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, _, _) => const ColoredBox(
                color: Color(0xFFE7E7E7),
                child: Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _CreationPhase {
  form,
  creating,
  generatingAvatar,
  generatingFullBody,
  preview,
  confirming,
  error,
}
