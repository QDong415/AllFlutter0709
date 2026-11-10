import 'package:all_flutter0709/app/router/app_routes.dart';
import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/core/account/account_guard.dart';
import 'package:all_flutter0709/core/cloud_storage/cloud_storage_service.dart';
import 'package:all_flutter0709/features/topic/data/models/topic_submit_media_model.dart';
import 'package:all_flutter0709/features/topic/presentation/helpers/topic_media_pick_helper.dart';
import 'package:all_flutter0709/features/topic/presentation/widgets/topic_submit_media_grid.dart';
import 'package:all_flutter0709/features/user/data/user_repository.dart';
import 'package:all_flutter0709/features/user/presentation/helpers/opinion_photo_submit_helper.dart';
import 'package:all_flutter0709/shared/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:all_flutter0709/shared/widgets/app_toast.dart';

/// 打开意见或举报页。
Future<void> openWarningReportPage(
  BuildContext context, {
  String toUserId = '',
}) async {
  await context.push(AppRoutes.warningReport, extra: toUserId);
}

/// 意见或举报提交页，对齐 Android `WarningReportActivity`。
class WarningReportPage extends ConsumerStatefulWidget {
  const WarningReportPage({super.key, this.toUserId = ''});

  final String toUserId;

  @override
  ConsumerState<WarningReportPage> createState() => _WarningReportPageState();
}

class _WarningReportPageState extends ConsumerState<WarningReportPage> {
  final UserRepository _userRepository = const UserRepository();
  final TextEditingController _contentController = TextEditingController();
  final TopicMediaPickHelper _mediaPickHelper = const TopicMediaPickHelper();
  final List<TopicSubmitMediaModel> _mediaList = <TopicSubmitMediaModel>[];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remain = OpinionPhotoSubmitHelper.maxImageCount - _mediaList.length;
    if (remain <= 0) {
      return;
    }
    final picked = await _mediaPickHelper.pickImages(
      context: context,
      remainCount: remain,
    );
    if (picked.isNotEmpty) {
      setState(() => _mediaList.addAll(picked));
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    if (!context.ensureLoggedIn()) {
      return;
    }

    final content = _contentController.text.trim();
    if (content.isEmpty && _mediaList.isEmpty) {
      AppToast.show(context, '请填写内容或添加图片');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
    });

    try {
      String? photoArrayJson;
      if (_mediaList.isNotEmpty) {
        final helper = OpinionPhotoSubmitHelper(
          ref.read(cloudStorageServiceProvider),
        );
        photoArrayJson = await helper.buildPhotoArrayJson(_mediaList);
      }
      await _userRepository.submitOpinion(
        content: content,
        toUserId: widget.toUserId,
        photoArrayJson: photoArrayJson,
      );
      if (!mounted) {
        return;
      }
      AppToast.show(context, '提交成功');
      context.pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppToast.show(context, error.toString().replaceFirst('Exception: ', ''));
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
    final canAddMore =
        _mediaList.length < OpinionPhotoSubmitHelper.maxImageCount;

    return Scaffold(
      appBar: const CommonAppBar(title: '意见或举报'),
      backgroundColor: AppColors.bodyBackground,
      body: Column(
        children: [
          const Divider(height: 0.5, thickness: 0.5, color: AppColors.divider),
          ColoredBox(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                  child: Text(
                    '可以添加多张图片',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                TopicSubmitMediaGrid(
                  mediaList: _mediaList,
                  canAddMore: canAddMore && !_isSubmitting,
                  onAddTap: _pickImages,
                  onItemTap: (_) {},
                  onDeleteTap: (index) {
                    setState(() => _mediaList.removeAt(index));
                  },
                ),
                const SizedBox(height: 8),
              ],
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
