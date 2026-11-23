import 'package:all_flutter0709/shared/media/app_image_gallery_preview_page.dart';
import 'package:all_flutter0709/shared/media/gallery_preview_item.dart';
import 'package:all_flutter0709/shared/media/preview_save_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('快速横滑后切换页面且只有当前图片注册 Hero', (tester) async {
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

    var heroList = tester
        .widgetList<Hero>(find.byType(Hero))
        .toList(growable: false);
    expect(heroList, hasLength(1));
    expect(heroList.single.tag, 'first');

    await tester.fling(find.byType(PageView), const Offset(-80, 0), 3000);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 300));

    heroList = tester
        .widgetList<Hero>(find.byType(Hero))
        .toList(growable: false);
    expect(heroList, hasLength(1));
    expect(heroList.single.tag, 'second');
  });
}
