import 'dart:async';

import 'package:all_flutter0709/app/theme/app_system_ui.dart';
import 'package:all_flutter0709/shared/media/app_zoomable_image.dart';
import 'package:all_flutter0709/shared/media/gallery_live_video.dart';
import 'package:all_flutter0709/shared/media/gallery_preview_item.dart';
import 'package:all_flutter0709/shared/media/image_preview_save_actions.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

/// 多图全屏画廊预览：缩放、下滑关闭、长按保存。
class AppImageGalleryPreviewPage extends StatefulWidget {
  const AppImageGalleryPreviewPage({
    super.key,
    required this.itemList,
    required this.initialIndex,
    this.enableSave = true,
  }) : assert(itemList.length > 0),
       assert(initialIndex >= 0 && initialIndex < itemList.length);

  final List<GalleryPreviewItem> itemList;
  final int initialIndex;
  final bool enableSave;

  @override
  State<AppImageGalleryPreviewPage> createState() =>
      _AppImageGalleryPreviewPageState();
}

class _AppImageGalleryPreviewPageState
    extends State<AppImageGalleryPreviewPage> {
  late final PageController _pageController;
  final Set<int> _precacheIndexSet = <int>{};
  late int _currentIndex;
  double _overlayOpacity = 1;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheAround(_currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _precacheAround(int index) {
    for (final targetIndex in <int>[index - 1, index, index + 1]) {
      if (targetIndex < 0 ||
          targetIndex >= widget.itemList.length ||
          !_precacheIndexSet.add(targetIndex)) {
        continue;
      }
      unawaited(_precacheItem(targetIndex));
    }
  }

  Future<void> _precacheItem(int index) async {
    final imageProvider = switch (widget.itemList[index]) {
      GalleryImagePreviewItem(:final imageProvider) => imageProvider,
      GalleryLiveVideoPreviewItem(:final coverImageProvider) =>
        coverImageProvider,
    };
    try {
      await precacheImage(imageProvider, context);
    } catch (_) {
      // 预取失败不影响当前页自己的加载与错误展示。
    }
  }

  void _onLongPressSave(int index) {
    if (!widget.enableSave) {
      return;
    }
    final item = widget.itemList[index];
    switch (item) {
      case GalleryImagePreviewItem(:final saveSource):
        ImagePreviewSaveActions.showSaveSheet(context, saveSource: saveSource);
      case GalleryLiveVideoPreviewItem(:final saveSource):
        ImagePreviewSaveActions.showSaveVideoSheet(
          context,
          saveSource: saveSource,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FullscreenMediaSystemUi(
      child: DismissiblePage(
        direction: DismissiblePageDismissDirection.vertical,
        backgroundColor: Colors.black,
        startingOpacity: 1,
        dragSensitivity: 0.7,
        minRadius: 0,
        maxRadius: 24,
        onDragUpdate: (details) {
          final nextOpacity = details.opacity.clamp(0.0, 1.0);
          if (_overlayOpacity == nextOpacity) {
            return;
          }
          setState(() {
            _overlayOpacity = nextOpacity;
          });
        },
        onDismissed: () => Navigator.of(context).maybePop(),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: PhotoViewGestureDetectorScope(
                  axis: Axis.horizontal,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.itemList.length,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      if (_currentIndex == index) {
                        return;
                      }
                      setState(() {
                        _currentIndex = index;
                      });
                      _precacheAround(index);
                    },
                    itemBuilder: (context, index) {
                      final item = widget.itemList[index];
                      final isCurrentPage = index == _currentIndex;
                      return ClipRect(
                        child: switch (item) {
                          GalleryImagePreviewItem() => AppZoomableImage(
                            imageProvider: item.imageProvider,
                            placeholderImageProvider:
                                item.placeholderImageProvider,
                            heroTag: isCurrentPage ? item.heroTag : null,
                            maxScale: 4,
                            onTap: () => Navigator.of(context).maybePop(),
                            onLongPress: widget.enableSave
                                ? () => _onLongPressSave(index)
                                : null,
                          ),
                          GalleryLiveVideoPreviewItem() => GalleryLiveVideo(
                            key: ValueKey(index),
                            coverImageProvider: item.coverImageProvider,
                            placeholderImageProvider:
                                item.placeholderImageProvider,
                            videoUrl: item.videoUrl,
                            videoPath: item.videoPath,
                            heroTag: isCurrentPage ? item.heroTag : null,
                            active: isCurrentPage,
                            onTap: () => Navigator.of(context).maybePop(),
                            onLongPress: widget.enableSave
                                ? () => _onLongPressSave(index)
                                : null,
                          ),
                        },
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 16,
                right: 16,
                child: _GalleryPreviewTopBar(
                  opacity: _overlayOpacity,
                  currentIndex: _currentIndex,
                  total: widget.itemList.length,
                  onBackTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryPreviewTopBar extends StatelessWidget {
  const _GalleryPreviewTopBar({
    required this.opacity,
    required this.currentIndex,
    required this.total,
    required this.onBackTap,
  });

  final double opacity;
  final int currentIndex;
  final int total;
  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Row(
        children: [
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Colors.black45,
              foregroundColor: Colors.white,
            ),
            onPressed: onBackTap,
            icon: const Icon(Icons.arrow_back),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${currentIndex + 1}/$total',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
