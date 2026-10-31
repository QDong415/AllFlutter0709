import 'package:all_flutter0709/app/theme/app_colors.dart';
import 'package:all_flutter0709/features/topic/presentation/topic_publish_controller.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

/// 动态列表顶部的发布进度条，对齐 Android `uploading_ll`。
class TopicSubmitProgressBar extends StatelessWidget {
  const TopicSubmitProgressBar({super.key, required this.controller});

  final TopicPublishController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.isVisible) {
          return const SizedBox.shrink();
        }
        return ColoredBox(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    if (controller.coverFile != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: _UploadCover(controller: controller),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          controller.statusText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            color: controller.isFailed
                                ? Colors.red
                                : const Color(0xFF5B5B5B),
                          ),
                        ),
                      ),
                    ),
                    if (controller.canRetry)
                      IconButton(
                        onPressed: () => controller.retry(),
                        icon: const Icon(Icons.refresh, size: 22),
                      ),
                    IconButton(
                      onPressed: controller.cancel,
                      icon: const Icon(Icons.close, size: 22),
                    ),
                  ],
                ),
              ),
              LinearProgressIndicator(
                minHeight: 2,
                value: controller.isFailed ? 0 : controller.progress,
                backgroundColor: const Color(0xFFEDEDED),
                color: AppColors.link,
              ),
              const Divider(height: 0.5),
            ],
          ),
        );
      },
    );
  }
}

/// 上传条封面。视频用相册缩略图，对齐 Android `Glide.load(path)`。
class _UploadCover extends StatelessWidget {
  const _UploadCover({required this.controller});

  final TopicPublishController controller;

  @override
  Widget build(BuildContext context) {
    final asset = controller.coverAsset;
    if (controller.coverIsVideo && asset != null) {
      return AssetEntityImage(
        asset,
        isOriginal: false,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFF333333)),
      );
    }
    if (controller.coverIsVideo) {
      return const ColoredBox(
        color: Color(0xFF333333),
        child: Icon(Icons.play_arrow, color: Colors.white, size: 20),
      );
    }
    final file = controller.coverFile;
    if (file == null) {
      return const SizedBox.shrink();
    }
    return Image.file(file, fit: BoxFit.cover);
  }
}
