import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/features/user/data/user_repository.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 打开意见或举报页。
void openWarningReportPage(BuildContext context, {String toUserId = ''}) {
  context.push(AppRoutes.warningReport, extra: toUserId);
}

/// 意见或举报提交页，对齐 Android `WarningReportActivity`。
class WarningReportPage extends StatefulWidget {
  const WarningReportPage({super.key, this.toUserId = ''});

  final String toUserId;

  @override
  State<WarningReportPage> createState() => _WarningReportPageState();
}

class _WarningReportPageState extends State<WarningReportPage> {
  final UserRepository _userRepository = const UserRepository();
  final TextEditingController _contentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    if (!context.ensureLoggedIn()) {
      return;
    }

    final content = _contentController.text.trim();
    if (content.isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
    });

    try {
      await _userRepository.submitOpinion(
        content: content,
        toUserId: widget.toUserId,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('提交成功')));
      context.pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
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
      appBar: const CommonAppBar(title: '意见或举报'),
      backgroundColor: AppColors.bodyBackground,
      body: Column(
        children: [
          const Divider(height: 0.5, thickness: 0.5, color: AppColors.divider),
          ColoredBox(
            color: Colors.white,
            child: TextField(
              controller: _contentController,
              enabled: !_isSubmitting,
              minLines: 6,
              maxLines: 8,
              maxLength: 200,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                hintText: '说点什么吧',
                hintStyle: TextStyle(color: Color(0xFFB3B3B8), fontSize: 16),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(8),
                counterText: '',
              ),
              style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
            ),
          ),
          const Divider(height: 0.5, thickness: 0.5, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 28, 40, 28),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.link,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.link.withValues(
                    alpha: 0.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('提交'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
