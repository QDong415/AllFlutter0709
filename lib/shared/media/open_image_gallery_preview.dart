import 'package:all_flutter0709/shared/media/app_image_gallery_preview_page.dart';
import 'package:all_flutter0709/shared/media/gallery_preview_item.dart';
import 'package:flutter/material.dart';

/// 以统一转场打开多图全屏画廊预览。
Future<void> openImageGalleryPreview(
  BuildContext context, {
  required List<GalleryPreviewItem> itemList,
  required int initialIndex,
  bool enableSave = true,
}) {
  if (itemList.isEmpty) {
    return Future<void>.value();
  }
  final safeIndex = initialIndex.clamp(0, itemList.length - 1);

  return Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AppImageGalleryPreviewPage(
          itemList: itemList,
          initialIndex: safeIndex,
          enableSave: enableSave,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final scale = Tween<double>(begin: 0.96, end: 1.0).animate(fade);
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    ),
  );
}
