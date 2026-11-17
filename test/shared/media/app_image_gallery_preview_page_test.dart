import 'package:all_flutter0709/shared/media/app_image_gallery_preview_page.dart';
import 'package:all_flutter0709/shared/media/gallery_preview_item.dart';
import 'package:all_flutter0709/shared/media/preview_save_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_view/photo_view.dart';

void main() {
  testWidgets('横滑后只有当前图片注册 Hero', (tester) async {
    const imageProvider = AssetImage('assets/icons/app_logo.png');
    final itemList = <GalleryPreviewItem>[
      GalleryPreviewItem(
        imageProvider: imageProvider,
        saveSource: const PreviewSaveFromUrl('https://example.com/1.png'),
        heroTag: 'first',
      ),
      GalleryPreviewItem(
        imageProvider: imageProvider,
        saveSource: const PreviewSaveFromUrl('https://example.com/2.png'),
        heroTag: 'second',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: AppImageGalleryPreviewPage(
          itemList: itemList,
          initialIndex: 0,
          enableSave: false,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    var heroPhotoViewList = tester
        .widgetList<PhotoView>(find.byType(PhotoView))
        .where((photoView) => photoView.heroAttributes != null)
        .toList(growable: false);
    expect(heroPhotoViewList, hasLength(1));
    expect(heroPhotoViewList.single.heroAttributes?.tag, 'first');

    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pump(const Duration(milliseconds: 500));

    heroPhotoViewList = tester
        .widgetList<PhotoView>(find.byType(PhotoView))
        .where((photoView) => photoView.heroAttributes != null)
        .toList(growable: false);
    expect(heroPhotoViewList, hasLength(1));
    expect(heroPhotoViewList.single.heroAttributes?.tag, 'second');
  });
}
