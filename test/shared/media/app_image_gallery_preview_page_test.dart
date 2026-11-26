import 'package:all_flutter0709/shared/media/app_image_gallery_preview_page.dart';
import 'package:all_flutter0709/shared/media/gallery_live_video.dart';
import 'package:all_flutter0709/shared/media/gallery_preview_item.dart';
import 'package:all_flutter0709/shared/media/preview_save_source.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_view/photo_view.dart';

void main() {
  test('竖向视频比静图宽时从左边裁，横图拉升铺满', () {
    final portrait = videoPlacement(
      video: const Size(1280, 2270),
      frame: const Size(390, 760),
    );
    expect(portrait.fit, BoxFit.cover);
    expect(portrait.alignment, Alignment.centerRight);

    final landscape = videoPlacement(
      video: const Size(1280, 720),
      frame: const Size(390, 220),
    );
    expect(landscape.fit, BoxFit.fill);
    expect(landscape.alignment, Alignment.center);
  });

  const imageProvider = AssetImage('assets/icons/app_logo.png');

  void usePortraitViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);
  }

  Future<void> doubleTapAt(WidgetTester tester, Offset position) async {
    final gesture = await tester.startGesture(position);
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 50));
    final secondGesture = await tester.startGesture(position);
    await secondGesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
  }

  testWidgets('Live 单击延迟收回，双击按点击位置放大且不收回', (tester) async {
    usePortraitViewport(tester);
    final scaleController = PhotoViewController();
    addTearDown(scaleController.dispose);
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: GalleryLiveVideo(
            coverImageProvider: imageProvider,
            videoUrl: 'https://example.com/live.mp4',
            active: true,
            scaleController: scaleController,
            onTap: () => tapCount++,
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await precacheImage(
        imageProvider,
        tester.element(find.byType(GalleryLiveVideo)),
      );
    });
    await tester.pump(const Duration(milliseconds: 300));
    final initialScale = scaleController.scale!;

    await tester.tap(find.byType(GalleryLiveVideo));
    await tester.pump();
    expect(tapCount, 0);
    await tester.pump(kDoubleTapTimeout);
    await tester.pump();
    expect(tapCount, 1);

    await doubleTapAt(tester, const Offset(200, 400));
    expect(scaleController.scale, closeTo(initialScale * 2, 0.01));
    expect(tapCount, 1);

    await doubleTapAt(tester, const Offset(200, 400));
    expect(scaleController.scale, closeTo(initialScale, 0.01));
    expect(tapCount, 1);

    await doubleTapAt(tester, const Offset(80, 400));
    expect(scaleController.scale, greaterThan(initialScale));
    expect(scaleController.position.dx, greaterThan(1));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('快速横滑后切换页面且只有当前图片注册 Hero', (tester) async {
    const imageProvider = AssetImage('assets/icons/app_logo.png');
    final itemList = <GalleryPreviewItem>[
      GalleryImagePreviewItem(
        imageProvider: imageProvider,
        saveSource: const PreviewSaveFromUrl('https://example.com/1.png'),
        heroTag: 'first',
      ),
      GalleryImagePreviewItem(
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

  testWidgets('横滑到 Live 页后暂停上一页并只给当前封面挂 Hero', (tester) async {
    const imageProvider = AssetImage('assets/icons/app_logo.png');
    final itemList = <GalleryPreviewItem>[
      GalleryImagePreviewItem(
        imageProvider: imageProvider,
        saveSource: const PreviewSaveFromUrl('https://example.com/1.png'),
        heroTag: 'still',
      ),
      GalleryLiveVideoPreviewItem(
        coverImageProvider: imageProvider,
        videoUrl: 'https://example.com/live.mp4',
        saveSource: const PreviewSaveFromUrl('https://example.com/live.mp4'),
        heroTag: 'live',
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

    expect(find.text('1/2'), findsOneWidget);
    for (final live in tester.widgetList<GalleryLiveVideo>(
      find.byType(GalleryLiveVideo),
    )) {
      expect(live.active, isFalse);
    }

    await tester.fling(find.byType(PageView), const Offset(-80, 0), 3000);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('2/2'), findsOneWidget);
    final liveList = tester
        .widgetList<GalleryLiveVideo>(find.byType(GalleryLiveVideo))
        .toList();
    expect(liveList.where((live) => live.active), hasLength(1));
    final heroList = tester.widgetList<Hero>(find.byType(Hero)).toList();
    expect(heroList, hasLength(1));
    expect(heroList.single.tag, 'live');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
