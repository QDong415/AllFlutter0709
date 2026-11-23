import 'package:all_flutter0709/shared/media/app_zoomable_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_view/photo_view.dart';

void main() {
  const imageProvider = AssetImage('assets/icons/app_logo.png');

  test('双击目标根据图片方向选择', () {
    expect(
      appPhotoViewScaleStateCycle(
        PhotoViewScaleState.initial,
        isLandscapeImage: true,
      ),
      PhotoViewScaleState.covering,
    );
    expect(
      appPhotoViewScaleStateCycle(PhotoViewScaleState.initial),
      PhotoViewScaleState.originalSize,
    );
  });

  Future<void> doubleTapAt(WidgetTester tester, Offset position) async {
    final gesture = await tester.startGesture(position);
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 50));
    final secondGesture = await tester.startGesture(position);
    await secondGesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
  }

  void usePortraitViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);
  }

  testWidgets('原图加载前显示缩略图底图', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppZoomableImage(
            imageProvider: imageProvider,
            placeholderImageProvider: imageProvider,
          ),
        ),
      ),
    );

    final placeholderImage = tester.widget<Image>(find.byType(Image));
    expect(placeholderImage.image, imageProvider);
    expect(placeholderImage.fit, BoxFit.contain);
  });

  testWidgets('双击一次放大，再次双击复位且不误触单击', (tester) async {
    usePortraitViewport(tester);
    final controller = PhotoViewController();
    addTearDown(controller.dispose);
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: AppZoomableImage(
            imageProvider: imageProvider,
            controller: controller,
            onTap: () => tapCount++,
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await precacheImage(
        imageProvider,
        tester.element(find.byType(AppZoomableImage)),
      );
    });
    await tester.pump(const Duration(milliseconds: 300));
    final initialScale = controller.scale!;

    await doubleTapAt(tester, const Offset(200, 400));
    expect(controller.scale, closeTo(initialScale * 2, 0.01));
    expect(tapCount, 0);

    await doubleTapAt(tester, const Offset(200, 400));
    expect(controller.scale, closeTo(initialScale, 0.01));
    expect(tapCount, 0);
  });

  testWidgets('偏离中心双击时按双击点聚焦', (tester) async {
    usePortraitViewport(tester);
    final controller = PhotoViewController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: AppZoomableImage(
            imageProvider: imageProvider,
            controller: controller,
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await precacheImage(
        imageProvider,
        tester.element(find.byType(AppZoomableImage)),
      );
    });
    await tester.pump(const Duration(milliseconds: 300));
    final initialScale = controller.scale!;

    await doubleTapAt(tester, const Offset(80, 400));
    expect(controller.scale, greaterThan(initialScale));
    expect(controller.position.dx, greaterThan(1));
  });
}
